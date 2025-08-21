#!/bin/bash

# Demo-CI Multi-Repository Build Script
# This script orchestrates the build process across all repositories in the workspace

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
PARALLEL_JOBS=$(nproc)
BUILD_TYPE="${BUILD_TYPE:-Release}"
VERBOSE="${VERBOSE:-false}"

# Repository paths (relative to workspace root)
STATIC_LIB_PATH="libs/calculator"
APPLICATION_PATH="application"
TOOLCHAIN_PATH="toolchain"

# Build artifacts directory
ARTIFACTS_DIR="$BUILD_DIR/artifacts"
LOGS_DIR="$BUILD_DIR/logs"

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

# Logging functions
log_command() {
    local component=$1
    local command=$2
    local log_file="$LOGS_DIR/${component}.log"
    
    if [ "$VERBOSE" = "true" ]; then
        echo "Running: $command" | tee -a "$log_file"
        eval "$command" 2>&1 | tee -a "$log_file"
    else
        echo "Running: $command" >> "$log_file"
        eval "$command" >> "$log_file" 2>&1
    fi
}

# Environment validation
check_workspace() {
    print_header "Validating Workspace Environment"
    
    # Check if we have the required directory structure for building
    local missing_dirs=()
    
    if [ ! -d "$WORKSPACE_ROOT/$STATIC_LIB_PATH" ]; then
        missing_dirs+=("static_library -> $STATIC_LIB_PATH")
    fi
    
    if [ ! -d "$WORKSPACE_ROOT/$APPLICATION_PATH" ]; then
        missing_dirs+=("application -> $APPLICATION_PATH")
    fi
    
    if [ ${#missing_dirs[@]} -gt 0 ]; then
        print_error "Missing required source directories:"
        for dir in "${missing_dirs[@]}"; do
            print_error "  $dir"
        done
        print_info "Please ensure the workspace is properly set up with all required repositories"
        print_info "You can use scripts/setup-workspace.sh to initialize the workspace"
        exit 1
    fi
    
    print_success "All required source directories found"
    
    # Create build directories
    mkdir -p "$ARTIFACTS_DIR" "$LOGS_DIR"
    print_success "Build environment prepared"
}

# Dependency checks
check_dependencies() {
    print_header "Checking Build Dependencies"
    
    local missing_deps=()
    
    # Check essential build tools
    command -v make >/dev/null 2>&1 || missing_deps+=("make")
    command -v g++ >/dev/null 2>&1 || missing_deps+=("g++")
    command -v ar >/dev/null 2>&1 || missing_deps+=("ar")
    
    # Check optional tools
    local optional_tools=()
    command -v cppcheck >/dev/null 2>&1 || optional_tools+=("cppcheck")
    command -v clang-format >/dev/null 2>&1 || optional_tools+=("clang-format")
    command -v valgrind >/dev/null 2>&1 || optional_tools+=("valgrind")
    command -v doxygen >/dev/null 2>&1 || optional_tools+=("doxygen")
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            print_error "  $dep"
        done
        print_info "Install with: sudo apt-get install build-essential"
        exit 1
    fi
    
    print_success "All required dependencies found"
    
    if [ ${#optional_tools[@]} -gt 0 ]; then
        print_warning "Optional tools not found (features will be skipped):"
        for tool in "${optional_tools[@]}"; do
            print_warning "  $tool"
        done
    fi
}

# Clean previous builds
clean_builds() {
    print_header "Cleaning Previous Builds"
    
    # Clean static library
    if [ -d "$WORKSPACE_ROOT/$STATIC_LIB_PATH" ]; then
        print_step "Cleaning static library..."
        cd "$WORKSPACE_ROOT/$STATIC_LIB_PATH"
        log_command "static_lib_clean" "make clean"
        print_success "Static library cleaned"
    fi
    
    # Clean application
    if [ -d "$WORKSPACE_ROOT/$APPLICATION_PATH" ]; then
        print_step "Cleaning application..."
        cd "$WORKSPACE_ROOT/$APPLICATION_PATH"
        log_command "application_clean" "make clean"
        print_success "Application cleaned"
    fi
    
    # Clean build artifacts
    print_step "Cleaning build artifacts..."
    rm -rf "$ARTIFACTS_DIR"/* "$LOGS_DIR"/*
    print_success "Build artifacts cleaned"
    
    cd "$BUILD_DIR"
}

# Build static library
build_static_library() {
    print_header "Building Static Library"
    
    cd "$WORKSPACE_ROOT/$STATIC_LIB_PATH"
    
    print_step "Building static library..."
    if [ "$BUILD_TYPE" = "Debug" ]; then
        log_command "static_lib_build" "make debug -j$PARALLEL_JOBS"
    else
        log_command "static_lib_build" "make static -j$PARALLEL_JOBS"
    fi
    
    # Verify library was created
    if [ -f "lib/libcalculator.a" ]; then
        print_success "Static library built successfully"
        
        # Copy to artifacts
        cp lib/libcalculator.a "$ARTIFACTS_DIR/"
        cp include/*.h "$ARTIFACTS_DIR/"
        
        # Show library info
        local lib_size=$(ls -lh lib/libcalculator.a | awk '{print $5}')
        print_info "Library size: $lib_size"
        
        if command -v nm >/dev/null 2>&1; then
            local symbol_count=$(nm -g lib/libcalculator.a | wc -l)
            print_info "Exported symbols: $symbol_count"
        fi
    else
        print_error "Static library build failed"
        print_info "Check log: $LOGS_DIR/static_lib_build.log"
        exit 1
    fi
    
    cd "$BUILD_DIR"
}

# Build application
build_application() {
    print_header "Building Application"
    
    cd "$WORKSPACE_ROOT/$APPLICATION_PATH"
    
    print_step "Building application..."
    if [ "$BUILD_TYPE" = "Debug" ]; then
        log_command "application_build" "make debug -j$PARALLEL_JOBS"
    else
        log_command "application_build" "make -j$PARALLEL_JOBS"
    fi
    
    # Verify application was created
    if [ -f "calculator" ]; then
        print_success "Application built successfully"
        
        # Copy to artifacts
        cp calculator "$ARTIFACTS_DIR/"
        
        # Show application info
        local app_size=$(ls -lh calculator | awk '{print $5}')
        print_info "Application size: $app_size"
        
        if command -v ldd >/dev/null 2>&1; then
            print_info "Dependencies:"
            ldd calculator | grep -E "(libc|libstdc|libgcc)" | sed 's/^/  /'
        fi
    else
        print_error "Application build failed"
        print_info "Check log: $LOGS_DIR/application_build.log"
        exit 1
    fi
    
    cd "$BUILD_DIR"
}

# Run tests
run_tests() {
    print_header "Running Tests"
    
    # Test static library
    print_step "Testing static library..."
    cd "$WORKSPACE_ROOT/$STATIC_LIB_PATH"
    if log_command "static_lib_test" "make test"; then
        print_success "Static library tests passed"
    else
        print_error "Static library tests failed"
        print_info "Check log: $LOGS_DIR/static_lib_test.log"
        return 1
    fi
    
    # Test application
    print_step "Testing application..."
    cd "$WORKSPACE_ROOT/$APPLICATION_PATH"
    if log_command "application_test" "make test"; then
        print_success "Application tests passed"
    else
        print_error "Application tests failed"
        print_info "Check log: $LOGS_DIR/application_test.log"
        return 1
    fi
    
    cd "$BUILD_DIR"
}

# Static analysis
run_static_analysis() {
    print_header "Running Static Analysis"
    
    if ! command -v cppcheck >/dev/null 2>&1; then
        print_warning "cppcheck not available, skipping static analysis"
        return 0
    fi
    
    # Analyze static library
    print_step "Analyzing static library..."
    cd "$WORKSPACE_ROOT/$STATIC_LIB_PATH"
    if log_command "static_lib_analysis" "make analyze"; then
        print_success "Static library analysis completed"
    else
        print_warning "Static library analysis issues found"
    fi
    
    # Analyze application
    print_step "Analyzing application..."
    cd "$WORKSPACE_ROOT/$APPLICATION_PATH"
    if log_command "application_analysis" "make analyze"; then
        print_success "Application analysis completed"
    else
        print_warning "Application analysis issues found"
    fi
    
    cd "$BUILD_DIR"
}

# Memory testing
run_memory_tests() {
    print_header "Running Memory Tests"
    
    if ! command -v valgrind >/dev/null 2>&1; then
        print_warning "valgrind not available, skipping memory tests"
        return 0
    fi
    
    cd "$WORKSPACE_ROOT/$APPLICATION_PATH"
    
    print_step "Running memory leak detection..."
    if log_command "memory_test" "valgrind --leak-check=full --error-exitcode=1 ./calculator"; then
        print_success "Memory tests passed - no leaks detected"
    else
        print_warning "Memory test issues found"
        print_info "Check log: $LOGS_DIR/memory_test.log"
    fi
    
    cd "$BUILD_DIR"
}

# Generate documentation
generate_docs() {
    print_header "Generating Documentation"
    
    if ! command -v doxygen >/dev/null 2>&1; then
        print_warning "doxygen not available, skipping documentation generation"
        return 0
    fi
    
    # Generate application documentation
    cd "$WORKSPACE_ROOT/$APPLICATION_PATH"
    if [ -f "Doxyfile" ]; then
        print_step "Generating application documentation..."
        if log_command "docs_generation" "make docs"; then
            print_success "Application documentation generated"
            
            # Copy to artifacts
            if [ -d "docs/html" ]; then
                cp -r docs/html "$ARTIFACTS_DIR/docs-application"
            fi
        else
            print_warning "Documentation generation failed"
        fi
    fi
    
    cd "$BUILD_DIR"
}

# Create build report
create_build_report() {
    print_header "Creating Build Report"
    
    local report_file="$ARTIFACTS_DIR/build-report.txt"
    
    cat > "$report_file" << EOF
Demo-CI Multi-Repository Build Report
====================================

Build Information:
- Date: $(date)
- Build Type: $BUILD_TYPE
- Parallel Jobs: $PARALLEL_JOBS
- Workspace: $WORKSPACE_ROOT

Build Artifacts:
EOF
    
    cd "$BUILD_DIR"
    find "$ARTIFACTS_DIR" -type f -exec ls -lh {} \; | sed 's/^/- /' >> "$report_file"
    
    cat >> "$report_file" << EOF

Build Logs:
EOF
    
    find "$LOGS_DIR" -name "*.log" -exec basename {} \; | sed 's/^/- /' >> "$report_file"
    
    print_success "Build report created: $report_file"
}

# Show usage
show_usage() {
    echo "Demo-CI Multi-Repository Build Script"
    echo ""
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  all          - Complete build pipeline (default)"
    echo "  clean        - Clean all previous builds"
    echo "  build        - Build library and application only"
    echo "  test         - Run tests only"
    echo "  analyze      - Run static analysis only"
    echo "  memory       - Run memory tests only"
    echo "  docs         - Generate documentation only"
    echo "  status       - Show workspace information (for repo status use setup-workspace.sh)"
    echo ""
    echo "Options:"
    echo "  --debug      - Build in debug mode"
    echo "  --release    - Build in release mode (default)"
    echo "  --verbose    - Verbose output"
    echo "  --parallel N - Use N parallel jobs (default: $(nproc))"
    echo "  --ignore-dirty - Continue with uncommitted changes"
    echo "  --help       - Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  BUILD_TYPE   - Release or Debug (default: Release)"
    echo "  VERBOSE      - true or false (default: false)"
    echo "  IGNORE_DIRTY - true or false (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Complete build pipeline"
    echo "  $0 --debug build     # Debug build only"
    echo "  $0 --verbose test    # Verbose test run"
    echo "  $0 clean build test  # Clean, build, and test"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                BUILD_TYPE="Debug"
                shift
                ;;
            --release)
                BUILD_TYPE="Release"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            --parallel)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            --ignore-dirty)
                IGNORE_DIRTY="true"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            clean|build|test|analyze|memory|docs|status|all)
                COMMANDS+=("$1")
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Default to 'all' if no commands specified
    if [ ${#COMMANDS[@]} -eq 0 ]; then
        COMMANDS=("all")
    fi
}

# Main execution
main() {
    local start_time=$(date +%s)
    
    echo -e "${GREEN}Demo-CI Multi-Repository Build System${NC}"
    echo "====================================="
    echo ""
    print_info "Build Type: $BUILD_TYPE"
    print_info "Parallel Jobs: $PARALLEL_JOBS"
    print_info "Verbose: $VERBOSE"
    echo ""
    
    # Always run environment checks
    check_workspace
    check_dependencies
    
    # Process commands
    for cmd in "${COMMANDS[@]}"; do
        case $cmd in
            clean)
                clean_builds
                ;;
            build)
                build_static_library
                build_application
                ;;
            test)
                run_tests
                ;;
            analyze)
                run_static_analysis
                ;;
            memory)
                run_memory_tests
                ;;
            docs)
                generate_docs
                ;;
            status)
                print_info "Repository status checking moved to setup-workspace.sh"
                print_info "Use: ./scripts/setup-workspace.sh status"
                ;;
            all)
                clean_builds
                build_static_library
                build_application
                run_tests
                run_static_analysis
                run_memory_tests
                generate_docs
                create_build_report
                ;;
        esac
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_header "Build Complete"
    print_success "Total time: ${duration}s"
    print_info "Artifacts: $ARTIFACTS_DIR"
    print_info "Logs: $LOGS_DIR"
}

# Initialize variables
COMMANDS=()

# Parse arguments and run
parse_args "$@"
main
