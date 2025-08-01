# Demo-CI Build System

[![Multi-Repository Build](https://github.com/Demo-CI/build/actions/workflows/build.yml/badge.svg)](https://github.com/Demo-CI/build/actions/workflows/build.yml)

Centralized build system for the Demo-CI multi-repository project.

## Overview

This repository contains the centralized build system that coordinates building and testing across multiple repositories:
- **application** - Main C++ calculator application
- **static_library** - Calculator math utilities library
- **toolchain** - Development tools and utilities

### Key Features
- ✅ **Automated multi-repository builds** triggered by source repository changes
- ✅ **Manifest-based workspace setup** ensuring identical local and CI environments
- ✅ **Comprehensive build scripts** for local development and CI
- ✅ **GitHub Actions integration** with repository dispatch
- ✅ **Cross-repository dependency management** via Google Repo tool
- ✅ **Artifact collection and reporting**

### Build Triggers
- Push to `application` repository → triggers centralized build
- Push to `static_library` repository → triggers centralized build
- Manual workflow dispatch for testing and debugging

### Required Setup for Repository Dispatch

**Important**: To enable cross-repository triggering, you need to set up a Personal Access Token:

1. **Create PAT**: Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate new token with permissions: `repo`, `workflow`

2. **Add to Source Repositories**: Add the PAT as a secret named `PAT_TOKEN` in:
   - `application` repository: Settings → Secrets and variables → Actions
   - `static_library` repository: Settings → Secrets and variables → Actions

3. **Why needed**: The default `GITHUB_TOKEN` cannot dispatch events to other repositories for security reasons

---

## GitHub Actions Integration

### Centralized Build Workflow

The repository includes a GitHub Actions workflow (`build.yml`) that provides centralized building:

**Workflow Name**: Multi-Repository Build  
**Triggers**:
- Repository dispatch from `application` and `static_library` repositories
- Manual workflow dispatch for testing

**Build Process**:
1. **Install Google Repo Tool** - Sets up repo tool in CI environment
2. **Setup Workspace with Manifest** - Uses manifest to create identical workspace structure
3. **Sync Repositories** - Fetches all repositories via `repo sync`
4. **Build Static Library** - Compiles the calculator library using build scripts
5. **Build Application** - Compiles the main application with library dependency
6. **Run Tests** - Executes test suites for both library and application using build scripts
7. **Collect Artifacts** - Gathers build outputs, logs, and reports

**Artifacts Created**:
- Application executable (`calculator`)
- Static library (`libcalculator.a`)
- Build logs and test reports
- Coverage and analysis reports

### Local and CI Consistency

**Identical Environments**: Both local development and CI use the same approach:

| Aspect | Local Development | GitHub Actions CI |
|--------|------------------|-------------------|
| **Workspace Setup** | `repo init -u .../manifest.git` | `repo init -u .../manifest.git` |
| **Repository Sync** | `repo sync` | `repo sync` |
| **Build Scripts** | `./scripts/build.sh` | `./scripts/build.sh` |
| **Directory Structure** | Standard repo workspace | Identical repo workspace |
| **Dependency Management** | Via manifest definitions | Via manifest definitions |

**Benefits**:
- ✅ **Reproducible builds** - Same environment locally and in CI
- ✅ **No CI-specific code** - Build scripts work identically everywhere  
- ✅ **Easy debugging** - Local environment matches CI exactly
- ✅ **Version consistency** - Manifest pins repository versions

### Monitoring Builds

- **Build Status**: Check the badge above or visit [Actions tab](https://github.com/Demo-CI/build/actions)
- **Build Logs**: Available in the workflow run details
- **Artifacts**: Downloadable from completed workflow runs

### Manual Triggering

You can manually trigger builds from the GitHub Actions tab:
1. Go to [Actions tab](https://github.com/Demo-CI/build/actions)
2. Select "Multi-Repository Build" workflow
3. Click "Run workflow"
4. Choose build options (all/library/application, debug/release)

---

## Complete Workflow: Manifest → Build → Test

### Step 1: Fetch Project via Manifest

#### Prerequisites: Install repo tool
```bash
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo
chmod +x ~/.local/bin/repo
export PATH="$HOME/.local/bin:$PATH"
```

#### Create workspace and fetch all repositories
```bash
mkdir demo-ci-workspace && cd demo-ci-workspace
repo init -u https://github.com/Demo-CI/manifest.git
repo sync

# Verify all repositories are fetched
repo list
```

Expected workspace structure:
```
demo-ci-workspace/
├── .repo/                 # Repo metadata
├── application/           # Main calculator application  
├── libs/calculator/       # Static library (from static_library repo)
├── build/                 # Build system with scripts
└── toolchain/             # Development tools
```

### Step 2: Build via Provided Scripts

The build repository contains comprehensive build scripts:

```bash
# Navigate to build directory
cd build

# Option 1: Complete build pipeline (recommended)
./run.sh build all           # Clean → Build → Test → Analyze → Docs

# Option 2: Individual build steps
./run.sh build clean         # Clean all previous builds
./run.sh build build         # Build static library and application only
./run.sh build test          # Run tests only
./run.sh build analyze       # Run static analysis only
./run.sh build docs          # Generate documentation only

# Check repository status
./run.sh build status        # Show repository status
```

### Step 3: Test via Build Scripts

```bash
# From build directory, run comprehensive tests
cd build

# Run all tests
./run.sh build test

# Or use individual scripts for detailed control
./run.sh ci test             # Run CI test suite
./run.sh ci analyze          # Static analysis
./run.sh ci memory           # Memory leak testing

# Manual verification
cd ../application
./calculator                 # Run the application
echo "5 + 3" | ./calculator  # Test with input
```

### Alternative: Using Build Scripts Directly

```bash
# If you want to use build scripts without full manifest setup
git clone https://github.com/Demo-CI/build.git
cd build

# The scripts can work with standalone repositories too
git clone https://github.com/Demo-CI/application.git ../application
git clone https://github.com/Demo-CI/static_library.git ../libs/calculator

# Run build pipeline
./run.sh build all
```

### Build Script Options

```bash
# Available run.sh commands:
./run.sh build               # Main build automation
./run.sh dev                 # Development workflow  
./run.sh ci                  # CI/CD pipeline helpers
./run.sh setup               # Workspace setup

# Build script commands:
./run.sh build all           # Complete pipeline (clean→build→test→analyze→docs)
./run.sh build clean         # Clean previous builds
./run.sh build build         # Build library and application only
./run.sh build test          # Run tests only
./run.sh build analyze       # Static analysis only
./run.sh build memory        # Memory leak testing
./run.sh build docs          # Generate documentation
./run.sh build status        # Repository status

# Build script flags:
./run.sh build all --debug           # Debug build
./run.sh build all --verbose         # Verbose output
./run.sh build all --parallel 4      # Use 4 parallel jobs
./run.sh build all --ignore-dirty    # Ignore uncommitted changes
```

### Expected Build Artifacts

After successful build via scripts:

```
build/
├── artifacts/                    # Collected build outputs
│   ├── calculator               # Application executable
│   ├── libcalculator.a         # Static library
│   ├── Calculator.h            # Header files
│   ├── MathUtils.h
│   └── build-report.txt        # Build summary
├── logs/                       # Build logs
│   ├── static_lib_build.log
│   ├── application_build.log
│   └── test_results.log
└── reports/                    # Analysis reports
    ├── static_analysis.txt
    ├── test_coverage.html
    └── memory_report.txt
```

## Troubleshooting

### Local Development Issues

```bash
# If build fails, check logs
cat build/logs/static_lib_build.log
cat build/logs/application_build.log

# Clean and retry
./run.sh build clean
./run.sh build all --verbose

# Check repository status
./run.sh build status
repo status

# Resync repositories
repo sync

# For permission issues
chmod +x build/run.sh
chmod +x build/scripts/*.sh
```

### GitHub Actions Issues

**Problem**: Build script fails with "Not in a repo workspace" error
```
❌ Not in a repo workspace. Please run this script from the build directory of a repo workspace.
```

**Solution**: The build scripts expect a Google Repo workspace structure. The GitHub Actions workflow creates a fake `.repo` directory to satisfy this validation:

```yaml
# Create fake .repo directory to satisfy build script workspace validation  
mkdir -p ../.repo
```

**Problem**: "Resource not accessible by integration" error in trigger workflows

**Solution**: Use Personal Access Token instead of GITHUB_TOKEN:
1. Create PAT with `repo` and `workflow` permissions
2. Add as `PAT_TOKEN` secret in source repositories
3. Update trigger workflows to use `${{ secrets.PAT_TOKEN }}`