#!/bin/bash

# Demo-CI Build System Entry Point
# Main script that delegates to specialized scripts in the scripts/ folder

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Helper functions
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

show_usage() {
    echo -e "${GREEN}Demo-CI Multi-Repository Build System${NC}"
    echo "====================================="
    echo ""
    echo "Usage: $0 <script> [arguments...]"
    echo ""
    echo "Available Scripts:"
    echo "  build     - Main build automation (scripts/build.sh)"
    echo "  dev       - Quick development workflow (scripts/dev.sh)"
    echo "  ci        - CI/CD pipeline helpers (scripts/ci.sh)"
    echo "  setup     - Workspace setup (scripts/setup-workspace.sh)"
    echo ""
    echo "Quick Commands:"
    echo "  $0 build                    # Complete build pipeline"
    echo "  $0 build --help             # Show build script help"
    echo "  $0 dev quick-build          # Fast development build"
    echo "  $0 dev watch                # Watch for changes"
    echo "  $0 ci ci-build              # CI build pipeline"
    echo "  $0 setup ~/workspace        # Setup new workspace"
    echo ""
    echo "Direct Script Access:"
    echo "  All scripts are in: $SCRIPTS_DIR"
    echo "  You can also call them directly:"
    echo "    ./scripts/build.sh --help"
    echo "    ./scripts/dev.sh status"
    echo "    ./scripts/ci.sh coverage"
    echo ""
    echo "Documentation:"
    echo "  Each script has detailed help with --help option"
}

main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    local script_name="$1"
    shift
    
    local script_path=""
    
    case "$script_name" in
        build)
            script_path="$SCRIPTS_DIR/build.sh"
            ;;
        dev)
            script_path="$SCRIPTS_DIR/dev.sh"
            ;;
        ci)
            script_path="$SCRIPTS_DIR/ci.sh"
            ;;
        setup)
            script_path="$SCRIPTS_DIR/setup-workspace.sh"
            ;;
        --help|help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown script: $script_name"
            echo ""
            show_usage
            exit 1
            ;;
    esac
    
    # Check if script exists
    if [ ! -f "$script_path" ]; then
        print_error "Script not found: $script_path"
        exit 1
    fi
    
    # Check if script is executable
    if [ ! -x "$script_path" ]; then
        print_error "Script not executable: $script_path"
        echo "Fix with: chmod +x $script_path"
        exit 1
    fi
    
    # Execute the script with all arguments
    exec "$script_path" "$@"
}

main "$@"
