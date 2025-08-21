#!/bin/bash

# Demo-CI CI/CD Helper Script
# For continuous integration and deployment workflows

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
ARTIFACTS_DIR="$BUILD_DIR/artifacts"
REPORTS_DIR="$BUILD_DIR/reports"

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
    echo -e "${BLUE}ℹ️  $1${NC}"
}

show_usage() {
    echo "Demo-CI CI/CD Helper Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  ci-build     - Complete CI build pipeline"
    echo "  ci-test      - Complete CI test pipeline"
    echo "  coverage     - Generate code coverage report"
    echo "  package      - Create deployment package"
    echo "  deploy-prep  - Prepare for deployment"
    echo "  quality      - Run quality checks"
    echo "  security     - Run security scans"
    echo ""
    echo "Options:"
    echo "  --no-color   - Disable colored output"
    echo "  --verbose    - Verbose output"
    echo "  --parallel N - Use N parallel jobs"
    echo ""
    echo "Examples:"
    echo "  $0 ci-build          # Full CI build"
    echo "  $0 ci-test           # Full CI test suite"
    echo "  $0 coverage          # Generate coverage report"
    echo "  $0 package           # Create release package"
}

setup_environment() {
    print_header "Setting Up CI Environment"
    
    # Create directories
    mkdir -p "$ARTIFACTS_DIR" "$REPORTS_DIR"
    
    # Install CI dependencies
    print_step "Installing CI dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y \
        build-essential \
        lcov \
        gcovr \
        cppcheck \
        clang-tidy \
        clang-format \
        valgrind \
        doxygen \
        graphviz \
        curl \
        jq || true
    
    print_success "CI environment ready"
}

ci_build() {
    print_header "CI Build Pipeline"
    
    setup_environment
    
    # Build with coverage
    print_step "Building with coverage instrumentation..."
    
    # Build static library with coverage
    cd "$WORKSPACE_ROOT/libs/calculator"
    make clean
    CXXFLAGS="-std=c++17 -Wall -Wextra -g -O0 --coverage -fprofile-arcs -ftest-coverage" make static
    
    # Build application with coverage
    cd "$WORKSPACE_ROOT/application"
    make clean
    CXXFLAGS="-std=c++17 -Wall -Wextra -g -O0 --coverage -fprofile-arcs -ftest-coverage" \
    LDFLAGS="--coverage" make
    
    print_success "CI build completed"
    cd "$BUILD_DIR"
}

ci_test() {
    print_header "CI Test Pipeline"
    
    # Unit tests
    print_step "Running unit tests..."
    
    cd "$WORKSPACE_ROOT/libs/calculator"
    make test
    
    cd "$WORKSPACE_ROOT/application"
    make test
    
    # Integration tests
    print_step "Running integration tests..."
    echo "2 + 2" | ./calculator
    echo "10 - 5" | ./calculator
    echo "3 * 4" | ./calculator
    echo "12 / 3" | ./calculator
    
    print_success "All tests passed"
    cd "$BUILD_DIR"
}

generate_coverage() {
    print_header "Generating Code Coverage Report"
    
    if ! command -v gcovr >/dev/null 2>&1; then
        print_warning "gcovr not available, installing..."
        pip3 install gcovr || sudo apt-get install -y python3-pip && pip3 install gcovr
    fi
    
    # Run tests to generate coverage data
    ci_test
    
    # Generate coverage reports
    print_step "Generating coverage reports..."
    
    cd "$WORKSPACE_ROOT"
    
    # HTML report
    gcovr -r . \
        --html-details "$REPORTS_DIR/coverage.html" \
        --exclude tests/ \
        --exclude build/ \
        --print-summary
    
    # XML report (for CI systems)
    gcovr -r . \
        --xml "$REPORTS_DIR/coverage.xml" \
        --exclude tests/ \
        --exclude build/
    
    # JSON report
    gcovr -r . \
        --json "$REPORTS_DIR/coverage.json" \
        --exclude tests/ \
        --exclude build/
    
    # Summary to console
    gcovr -r . \
        --exclude tests/ \
        --exclude build/
    
    print_success "Coverage report generated: $REPORTS_DIR/coverage.html"
    cd "$BUILD_DIR"
}

run_quality_checks() {
    print_header "Quality Checks"
    
    # Static analysis with cppcheck
    print_step "Running cppcheck static analysis..."
    
    cd "$WORKSPACE_ROOT"
    cppcheck --enable=all \
        --xml \
        --output-file="$REPORTS_DIR/cppcheck.xml" \
        --suppress=missingInclude \
        libs/calculator/src/ \
        libs/calculator/include/ \
        application/src/ \
        2>/dev/null || true
    
    # Also generate human-readable report
    cppcheck --enable=all \
        --suppress=missingInclude \
        libs/calculator/src/ \
        libs/calculator/include/ \
        application/src/ \
        > "$REPORTS_DIR/cppcheck.txt" 2>&1 || true
    
    # Code formatting check
    print_step "Checking code formatting..."
    
    cd "$WORKSPACE_ROOT/libs/calculator"
    if make format-check 2>/dev/null; then
        print_success "Code formatting OK"
    else
        print_warning "Code formatting issues found"
    fi
    
    cd "$WORKSPACE_ROOT/application"
    if make format-check 2>/dev/null; then
        print_success "Application formatting OK"
    else
        print_warning "Application formatting issues found"
    fi
    
    print_success "Quality checks completed"
    cd "$BUILD_DIR"
}

run_security_scan() {
    print_header "Security Scan"
    
    # Memory leak detection
    print_step "Running memory leak detection..."
    
    cd "$WORKSPACE_ROOT/application"
    
    # Valgrind memory check
    echo "2 + 2" | valgrind \
        --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        --xml=yes \
        --xml-file="$REPORTS_DIR/valgrind.xml" \
        ./calculator 2>/dev/null || true
    
    # Also generate human-readable report
    echo "2 + 2" | valgrind \
        --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        ./calculator > "$REPORTS_DIR/valgrind.txt" 2>&1 || true
    
    # Basic security checks with compiler
    print_step "Checking for security vulnerabilities..."
    
    # Rebuild with security flags
    make clean
    CXXFLAGS="-std=c++17 -Wall -Wextra -Werror -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    make || print_warning "Security build warnings found"
    
    print_success "Security scan completed"
    cd "$BUILD_DIR"
}

create_package() {
    print_header "Creating Deployment Package"
    
    local package_dir="$ARTIFACTS_DIR/package"
    local version=$(date +%Y%m%d-%H%M%S)
    
    # Create package structure
    mkdir -p "$package_dir"/{bin,lib,include,docs}
    
    # Copy binaries
    print_step "Packaging binaries..."
    cp "$WORKSPACE_ROOT/application/calculator" "$package_dir/bin/"
    cp "$WORKSPACE_ROOT/libs/calculator/lib/libcalculator.a" "$package_dir/lib/"
    
    # Copy headers
    print_step "Packaging headers..."
    cp "$WORKSPACE_ROOT/libs/calculator/include"/*.h "$package_dir/include/"
    
    # Copy documentation
    print_step "Packaging documentation..."
    if [ -d "$WORKSPACE_ROOT/application/docs/html" ]; then
        cp -r "$WORKSPACE_ROOT/application/docs/html" "$package_dir/docs/"
    fi
    
    # Create package metadata
    cat > "$package_dir/package.json" << EOF
{
    "name": "demo-ci-calculator",
    "version": "$version",
    "description": "Demo CI Calculator Application",
    "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "components": {
        "application": "calculator",
        "library": "libcalculator.a"
    },
    "files": {
        "bin": ["calculator"],
        "lib": ["libcalculator.a"],
        "include": ["Calculator.h", "MathUtils.h"]
    }
}
EOF
    
    # Create archive
    print_step "Creating archive..."
    cd "$ARTIFACTS_DIR"
    tar -czf "demo-ci-calculator-${version}.tar.gz" package/
    
    # Create checksums
    sha256sum "demo-ci-calculator-${version}.tar.gz" > "demo-ci-calculator-${version}.sha256"
    
    print_success "Package created: demo-ci-calculator-${version}.tar.gz"
    print_info "Package size: $(ls -lh demo-ci-calculator-${version}.tar.gz | awk '{print $5}')"
    
    cd "$BUILD_DIR"
}

deploy_preparation() {
    print_header "Deployment Preparation"
    
    # Create deployment scripts
    print_step "Creating deployment scripts..."
    
    cat > "$ARTIFACTS_DIR/install.sh" << 'EOF'
#!/bin/bash

# Demo-CI Calculator Installation Script

set -e

INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"

echo "Installing Demo-CI Calculator to $INSTALL_PREFIX"

# Install binary
sudo cp bin/calculator "$INSTALL_PREFIX/bin/"
sudo chmod +x "$INSTALL_PREFIX/bin/calculator"

# Install library
sudo cp lib/libcalculator.a "$INSTALL_PREFIX/lib/"

# Install headers
sudo mkdir -p "$INSTALL_PREFIX/include/demo-ci"
sudo cp include/*.h "$INSTALL_PREFIX/include/demo-ci/"

echo "Installation completed successfully!"
echo "Run 'calculator' to use the application"
EOF
    
    cat > "$ARTIFACTS_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

# Demo-CI Calculator Uninstallation Script

set -e

INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"

echo "Uninstalling Demo-CI Calculator from $INSTALL_PREFIX"

sudo rm -f "$INSTALL_PREFIX/bin/calculator"
sudo rm -f "$INSTALL_PREFIX/lib/libcalculator.a"
sudo rm -rf "$INSTALL_PREFIX/include/demo-ci"

echo "Uninstallation completed successfully!"
EOF
    
    chmod +x "$ARTIFACTS_DIR/install.sh" "$ARTIFACTS_DIR/uninstall.sh"
    
    # Create deployment manifest
    cat > "$ARTIFACTS_DIR/deployment.yml" << EOF
apiVersion: v1
kind: Deployment
metadata:
  name: demo-ci-calculator
  labels:
    app: calculator
    version: $(date +%Y%m%d-%H%M%S)
spec:
  replicas: 1
  selector:
    matchLabels:
      app: calculator
  template:
    metadata:
      labels:
        app: calculator
    spec:
      containers:
      - name: calculator
        image: demo-ci/calculator:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF
    
    print_success "Deployment preparation completed"
}

main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    local command="$1"
    shift
    
    echo -e "${GREEN}Demo-CI CI/CD Pipeline${NC}"
    echo "======================"
    echo ""
    
    case "$command" in
        ci-build)
            ci_build "$@"
            ;;
        ci-test)
            ci_test "$@"
            ;;
        coverage)
            generate_coverage "$@"
            ;;
        package)
            create_package "$@"
            ;;
        deploy-prep)
            deploy_preparation "$@"
            ;;
        quality)
            run_quality_checks "$@"
            ;;
        security)
            run_security_scan "$@"
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
