#!/bin/bash

# Demo-CI Quick Development Script
# Fast development workflow for common tasks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_ROOT="$(pwd)/.."
BUILD_DIR="$(pwd)"

# Helper functions
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

show_usage() {
    echo "Demo-CI Quick Development Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  quick-build  - Fast build (library + application)"
    echo "  quick-test   - Fast test run"
    echo "  watch        - Watch for changes and rebuild"
    echo "  clean-all    - Clean everything"
    echo "  format       - Format all code"
    echo "  status       - Show quick project status"
    echo "  benchmark    - Run performance benchmark"
    echo ""
    echo "Examples:"
    echo "  $0 quick-build      # Fast development build"
    echo "  $0 quick-test       # Run tests quickly"
    echo "  $0 watch            # Watch and rebuild on changes"
    echo "  $0 format           # Format all source code"
}

quick_build() {
    print_header "Quick Build"
    
    local start_time=$(date +%s)
    
    # Build static library
    print_step "Building static library..."
    cd "$WORKSPACE_ROOT/libs/calculator"
    make static -j$(nproc) || exit 1
    
    # Build application
    print_step "Building application..."
    cd "$WORKSPACE_ROOT/application"
    make -j$(nproc) || exit 1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "Quick build completed in ${duration}s"
    cd "$BUILD_DIR"
}

quick_test() {
    print_header "Quick Test"
    
    local start_time=$(date +%s)
    
    # Test static library
    print_step "Testing static library..."
    cd "$WORKSPACE_ROOT/libs/calculator"
    make test || exit 1
    
    # Test application
    print_step "Testing application..."
    cd "$WORKSPACE_ROOT/application"
    make test || exit 1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "Quick test completed in ${duration}s"
    cd "$BUILD_DIR"
}

watch_changes() {
    print_header "Watch Mode"
    
    if ! command -v inotifywait >/dev/null 2>&1; then
        print_warning "inotifywait not found, installing..."
        sudo apt-get update && sudo apt-get install -y inotify-tools
    fi
    
    print_info "Watching for changes in source files..."
    print_info "Press Ctrl+C to stop"
    
    # Initial build
    quick_build
    
    # Watch for changes
    while true; do
        inotifywait -r -e modify,create,delete \
            "$WORKSPACE_ROOT/libs/calculator/src" \
            "$WORKSPACE_ROOT/libs/calculator/include" \
            "$WORKSPACE_ROOT/application/src" \
            "$WORKSPACE_ROOT/application/include" \
            2>/dev/null
        
        echo ""
        print_info "Changes detected, rebuilding..."
        if quick_build; then
            print_success "Rebuild successful"
        else
            print_error "Rebuild failed"
        fi
        echo ""
    done
}

clean_all() {
    print_header "Clean All"
    
    # Clean static library
    print_step "Cleaning static library..."
    cd "$WORKSPACE_ROOT/libs/calculator"
    make clean
    
    # Clean application
    print_step "Cleaning application..."
    cd "$WORKSPACE_ROOT/application"
    make clean
    
    # Clean build artifacts
    print_step "Cleaning build artifacts..."
    rm -rf "$BUILD_DIR/artifacts" "$BUILD_DIR/logs"
    
    print_success "All cleaned"
    cd "$BUILD_DIR"
}

format_code() {
    print_header "Format Code"
    
    if ! command -v clang-format >/dev/null 2>&1; then
        print_warning "clang-format not found, installing..."
        sudo apt-get update && sudo apt-get install -y clang-format
    fi
    
    # Format static library
    print_step "Formatting static library..."
    cd "$WORKSPACE_ROOT/libs/calculator"
    if make format 2>/dev/null; then
        print_success "Static library formatted"
    else
        find src include -name "*.cpp" -o -name "*.h" | xargs clang-format -i
        print_success "Static library formatted (manual)"
    fi
    
    # Format application
    print_step "Formatting application..."
    cd "$WORKSPACE_ROOT/application"
    if make format 2>/dev/null; then
        print_success "Application formatted"
    else
        find src include -name "*.cpp" -o -name "*.h" | xargs clang-format -i 2>/dev/null || true
        print_success "Application formatted (manual)"
    fi
    
    cd "$BUILD_DIR"
}

show_status() {
    print_header "Project Status"
    
    # Repository status
    print_step "Repository Status:"
    cd "$WORKSPACE_ROOT"
    repo forall -c 'echo "  $(basename $REPO_PATH): $(git status --porcelain | wc -l) changes"'
    
    # Build status
    print_step "Build Status:"
    
    # Check static library
    if [ -f "$WORKSPACE_ROOT/libs/calculator/lib/libcalculator.a" ]; then
        local lib_time=$(stat -c %Y "$WORKSPACE_ROOT/libs/calculator/lib/libcalculator.a")
        local lib_size=$(ls -lh "$WORKSPACE_ROOT/libs/calculator/lib/libcalculator.a" | awk '{print $5}')
        print_info "  Static library: Built ($(date -d @$lib_time '+%H:%M:%S'), $lib_size)"
    else
        print_warning "  Static library: Not built"
    fi
    
    # Check application
    if [ -f "$WORKSPACE_ROOT/application/calculator" ]; then
        local app_time=$(stat -c %Y "$WORKSPACE_ROOT/application/calculator")
        local app_size=$(ls -lh "$WORKSPACE_ROOT/application/calculator" | awk '{print $5}')
        print_info "  Application: Built ($(date -d @$app_time '+%H:%M:%S'), $app_size)"
    else
        print_warning "  Application: Not built"
    fi
    
    # Disk usage
    print_step "Disk Usage:"
    cd "$WORKSPACE_ROOT"
    print_info "  Total workspace: $(du -sh . | cut -f1)"
    print_info "  Build artifacts: $(du -sh build/artifacts 2>/dev/null | cut -f1 || echo '0B')"
    print_info "  Object files: $(find . -name "*.o" -exec du -ch {} + 2>/dev/null | tail -1 | cut -f1 || echo '0B')"
    
    cd "$BUILD_DIR"
}

run_benchmark() {
    print_header "Performance Benchmark"
    
    # Ensure application is built
    if [ ! -f "$WORKSPACE_ROOT/application/calculator" ]; then
        print_step "Building application for benchmark..."
        quick_build
    fi
    
    cd "$WORKSPACE_ROOT/application"
    
    print_step "Running performance benchmark..."
    
    # Simple benchmark
    local start_time=$(date +%s.%N)
    
    # Run calculator multiple times
    for i in {1..100}; do
        echo "2 + 2" | ./calculator >/dev/null 2>&1 || true
    done
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    local ops_per_sec=$(echo "scale=2; 100 / $duration" | bc)
    
    print_success "Benchmark completed"
    print_info "  100 operations in ${duration}s"
    print_info "  ~${ops_per_sec} operations/second"
    
    # Memory usage
    if command -v valgrind >/dev/null 2>&1; then
        print_step "Memory usage analysis..."
        echo "2 + 2" | valgrind --tool=massif --massif-out-file=/tmp/massif.out ./calculator >/dev/null 2>&1 || true
        if [ -f /tmp/massif.out ]; then
            local peak_mem=$(grep mem_heap_B /tmp/massif.out | sed -e 's/mem_heap_B=\(.*\)/\1/' | sort -g | tail -1)
            if [ -n "$peak_mem" ]; then
                local peak_kb=$((peak_mem / 1024))
                print_info "  Peak memory usage: ${peak_kb}KB"
            fi
            rm -f /tmp/massif.out
        fi
    fi
    
    cd "$BUILD_DIR"
}

main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    local command="$1"
    shift
    
    echo -e "${GREEN}Demo-CI Quick Development${NC}"
    echo "========================="
    echo ""
    
    case "$command" in
        quick-build)
            quick_build "$@"
            ;;
        quick-test)
            quick_test "$@"
            ;;
        watch)
            watch_changes "$@"
            ;;
        clean-all)
            clean_all "$@"
            ;;
        format)
            format_code "$@"
            ;;
        status)
            show_status "$@"
            ;;
        benchmark)
            run_benchmark "$@"
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
