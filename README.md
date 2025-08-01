# Complete Workflow: Manifest → Build → Test

## Step 1: Fetch Project via Manifest

```bash
# Prerequisites: Install repo tool
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo
chmod +x ~/.local/bin/repo
export PATH="$HOME/.local/bin:$PATH"

# Create workspace and fetch all repositories
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

## Step 2: Build via Provided Scripts

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

## Step 3: Test via Build Scripts

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

## Alternative: Using Build Scripts Directly

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

## Build Script Options

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

## Expected Build Artifacts

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

```bash
# If build fails, check logs
cat build/logs/static_lib_build.log
cat build/logs/application_build.log

# Clean and retry
./run.sh clean
./run.sh build --verbose

# Check repository status
./run.sh status
repo status

# Resync repositories
repo sync

# For permission issues
chmod +x build/run.sh
chmod +x build/scripts/*.sh
```