#!/bin/bash

# Demo-CI Workspace Setup Script
# This script helps developers set up the multi-repository workspace

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_MANIFEST_URL="https://github.com/Demo-CI/manifest.git"
DEFAULT_MANIFEST_BRANCH="main"
DEFAULT_MANIFEST_FILE="default.xml"

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
    echo "Demo-CI Workspace Setup Script"
    echo ""
    echo "Usage: $0 [OPTIONS] <workspace_directory>"
    echo ""
    echo "Options:"
    echo "  --manifest-url URL    - Manifest repository URL (default: $DEFAULT_MANIFEST_URL)"
    echo "  --manifest-branch B   - Manifest branch (default: $DEFAULT_MANIFEST_BRANCH)"
    echo "  --manifest-file F     - Manifest file (default: $DEFAULT_MANIFEST_FILE)"
    echo "  --development         - Use development manifest (development.xml)"
    echo "  --production          - Use production manifest (production.xml)"
    echo "  --minimal             - Use minimal manifest (minimal.xml)"
    echo "  --help                - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 ~/workspace                    # Setup default workspace"
    echo "  $0 --development ~/dev-workspace  # Setup development workspace"
    echo "  $0 --production ~/prod-workspace  # Setup production workspace"
    echo ""
    echo "Prerequisites:"
    echo "  - Git installed and configured"
    echo "  - Google Repo tool installed"
    echo "  - Internet connection for repository access"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Git
    if ! command -v git >/dev/null 2>&1; then
        print_error "Git is not installed"
        print_info "Install with: sudo apt-get install git"
        exit 1
    fi
    print_success "Git found: $(git --version)"
    
    # Check Repo tool
    if ! command -v repo >/dev/null 2>&1; then
        print_error "Google Repo tool is not installed"
        print_info "Install instructions:"
        print_info "  mkdir -p ~/.bin"
        print_info "  PATH=\"\${HOME}/.bin:\${PATH}\""
        print_info "  curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo"
        print_info "  chmod a+rx ~/.bin/repo"
        exit 1
    fi
    print_success "Repo tool found"
    
    # Check Git configuration
    if ! git config --global user.name >/dev/null 2>&1 || ! git config --global user.email >/dev/null 2>&1; then
        print_warning "Git user configuration missing"
        print_info "Configure with:"
        print_info "  git config --global user.name \"Your Name\""
        print_info "  git config --global user.email \"your.email@example.com\""
        
        read -p "Continue without Git configuration? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        local git_name=$(git config --global user.name)
        local git_email=$(git config --global user.email)
        print_success "Git configured: $git_name <$git_email>"
    fi
}

setup_workspace() {
    local workspace_dir="$1"
    local manifest_url="$2"
    local manifest_branch="$3"
    local manifest_file="$4"
    
    print_header "Setting Up Workspace"
    
    # Create workspace directory
    print_step "Creating workspace directory: $workspace_dir"
    mkdir -p "$workspace_dir"
    cd "$workspace_dir"
    
    # Initialize repo
    print_step "Initializing repo workspace..."
    repo init -u "$manifest_url" -b "$manifest_branch" -m "$manifest_file"
    print_success "Repo workspace initialized"
    
    # Sync repositories
    print_step "Syncing repositories..."
    repo sync -j$(nproc)
    print_success "Repositories synced"
    
    # Show workspace status
    print_step "Workspace status:"
    repo status
    
    print_success "Workspace setup complete!"
    print_info "Workspace location: $workspace_dir"
    print_info "To start building:"
    print_info "  cd $workspace_dir/build"
    print_info "  ./scripts/build.sh"
}

validate_workspace() {
    local workspace_dir="$1"
    
    print_header "Validating Workspace"
    
    cd "$workspace_dir"
    
    # Check if .repo exists
    if [ ! -d ".repo" ]; then
        print_error "Not a repo workspace"
        return 1
    fi
    
    # Check required directories
    local required_dirs=("application" "build" "libs/calculator")
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [ ${#missing_dirs[@]} -gt 0 ]; then
        print_error "Missing required directories:"
        for dir in "${missing_dirs[@]}"; do
            print_error "  $dir"
        done
        print_info "Run 'repo sync' to fetch missing repositories"
        return 1
    fi
    
    print_success "Workspace validation passed"
    
    # Show repository versions
    print_info "Repository status:"
    repo forall -c 'echo "  $(basename $REPO_PATH): $(git rev-parse --short HEAD) ($(git symbolic-ref --short HEAD 2>/dev/null || echo detached))"'
    
    return 0
}

main() {
    local workspace_dir=""
    local manifest_url="$DEFAULT_MANIFEST_URL"
    local manifest_branch="$DEFAULT_MANIFEST_BRANCH"
    local manifest_file="$DEFAULT_MANIFEST_FILE"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --manifest-url)
                manifest_url="$2"
                shift 2
                ;;
            --manifest-branch)
                manifest_branch="$2"
                shift 2
                ;;
            --manifest-file)
                manifest_file="$2"
                shift 2
                ;;
            --development)
                manifest_file="development.xml"
                shift
                ;;
            --production)
                manifest_file="production.xml"
                shift
                ;;
            --minimal)
                manifest_file="minimal.xml"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$workspace_dir" ]; then
                    workspace_dir="$1"
                else
                    print_error "Multiple workspace directories specified"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate arguments
    if [ -z "$workspace_dir" ]; then
        print_error "Workspace directory not specified"
        show_usage
        exit 1
    fi
    
    # Convert to absolute path
    workspace_dir=$(realpath "$workspace_dir")
    
    echo -e "${GREEN}Demo-CI Workspace Setup${NC}"
    echo "======================="
    echo ""
    print_info "Workspace: $workspace_dir"
    print_info "Manifest URL: $manifest_url"
    print_info "Manifest Branch: $manifest_branch"
    print_info "Manifest File: $manifest_file"
    echo ""
    
    # Check if workspace already exists
    if [ -d "$workspace_dir" ] && [ "$(ls -A "$workspace_dir")" ]; then
        print_warning "Directory $workspace_dir already exists and is not empty"
        
        # Try to validate existing workspace
        if validate_workspace "$workspace_dir"; then
            print_info "Existing workspace appears valid"
            exit 0
        else
            read -p "Continue and overwrite? (y/N): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                print_info "Setup cancelled"
                exit 1
            fi
            rm -rf "$workspace_dir"
        fi
    fi
    
    # Run setup
    check_prerequisites
    setup_workspace "$workspace_dir" "$manifest_url" "$manifest_branch" "$manifest_file"
    validate_workspace "$workspace_dir"
    
    print_header "Next Steps"
    echo "1. Change to workspace directory:"
    echo "   cd $workspace_dir"
    echo ""
    echo "2. Build the project:"
    echo "   cd build && ./scripts/build.sh"
    echo ""
    echo "3. Run specific commands:"
    echo "   ./scripts/build.sh --help"
    echo ""
    echo "4. Update repositories:"
    echo "   repo sync"
    echo ""
    echo "5. Check status:"
    echo "   repo status"
}

main "$@"
