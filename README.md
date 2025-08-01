# Demo-CI Centralized Build System

[![Multi-Repository Build](https://github.com/Demo-CI/build/actions/workflows/build.yml/badge.svg)](https://github.com/Demo-CI/build/actions/workflows/build.yml)

**Centralized build system for the Demo-CI multi-repository C++ project with automated PR feedback and JSON comment triggers.**

## 🏗️ **System Overview**

This repository coordinates building and testing across multiple repositories:
- **[application](../application)** - C++ calculator application  
- **[static_library](../static_library)** - Calculator math utilities library
- **[manifest](../manifest)** - Workspace configuration for Google Repo tool

### Key Features
- ✅ **Automated multi-repository builds** triggered by source changes
- ✅ **JSON comment triggers** for custom build configurations in PRs
- ✅ **Automatic PR feedback** with detailed build results
- ✅ **Manifest-based workspace** ensuring identical local/CI environments
- ✅ **Cross-repository dependency management** via Google Repo tool

---

## 🚀 **Build Triggers**

### 1. Automatic Triggers
- **Pull Requests**: Any PR in application/static_library repos
- **Push Events**: Direct commits to main/develop branches

### 2. JSON Comment Triggers
Post a JSON comment in any Pull Request to customize builds:

```json
{
  "build_type": "debug",
  "save_logs": true,
  "reason": "Testing new feature"
}
```

**Parameters:**
- `build_type`: `"release"` (default) or `"debug"`
- `save_logs`: `true` or `false` (default) - saves detailed build logs
- `reason`: Custom description (optional)
- `action`: `"build"` (optional, auto-assumed)

### 3. Manual Workflow
Go to [Actions](../../actions) → "Multi-Repository Build" → "Run workflow"

---

## 🔄 **PR Feedback System**

When builds complete, results are automatically posted back to the source PR:

```
Developer posts JSON → Build triggers → Results posted back to PR
```

**Feedback includes:**
- ✅/❌ Overall build status with detailed step results  
- 🔧 Build configuration (type, logs, run number)
- 📦 Artifact availability and retention info
- 🔗 Direct links to build logs and artifacts

---

## 🛠️ **Setup Requirements**

### PAT Token Configuration
To enable cross-repository triggering, configure a Personal Access Token:

1. **Create PAT**: GitHub Settings → Developer settings → Personal access tokens
   - Permissions: `repo`, `workflow`

2. **Add to Organization**: Add as organization secret `PAT_TOKEN` in:
   - [Demo-CI Organization Settings](https://github.com/organizations/Demo-CI/settings/secrets/actions)
   - This automatically makes the secret available to all repositories in the organization

3. **Why needed**: Default `GITHUB_TOKEN` cannot dispatch to other repositories

**Benefits of Organization-level PAT:**
- ✅ **Single configuration** - No need to add to each repository
- ✅ **Automatic availability** - All current and future repositories inherit the secret
- ✅ **Centralized management** - Update once, applies everywhere

---

## 🏭 **Build Process**

1. **Workspace Setup** - Google Repo tool syncs all repositories via manifest
2. **Static Library** - Builds calculator math utilities (`libcalculator.a`)
3. **Application** - Builds main calculator app with library dependency
4. **Tests** - Runs comprehensive test suites
5. **Artifacts** - Collects executables, libraries, logs, and reports

**Artifacts Created:**
- 📱 Application executable (`calculator`)
- 📚 Static library (`libcalculator.a`)
- 📝 Build logs (when `save_logs: true`)
- 📊 Test reports and coverage data

---

## 🔧 **Local Development**

### Quick Start
```bash
# Setup workspace (identical to CI)
repo init -u https://github.com/Demo-CI/manifest.git
repo sync

# Build everything
cd build
./scripts/build.sh build

# Run tests
./scripts/build.sh test
```

### Local/CI Consistency
| Aspect | Local | CI |
|--------|-------|-----|
| Workspace | `repo sync` | `repo sync` |
| Build | `./scripts/build.sh` | `./scripts/build.sh` |
| Tests | `./scripts/build.sh test` | `./scripts/build.sh test` |

**Benefits:** Identical environments ensure reproducible builds and easy debugging.

---

## 📊 **Monitoring & Debugging**

- **Build Status**: [Actions tab](../../actions) or badge above
- **Build Logs**: Available in workflow run details  
- **Artifacts**: Downloadable from completed runs
- **PR Feedback**: Automatic comments with build results

### Troubleshooting
- **Build not triggering?** Check PAT_TOKEN secrets configuration
- **JSON comment ignored?** Verify format and ensure it's in a PR
- **Missing feedback?** Check PAT_TOKEN has `repo` scope

---

## 📁 **Repository Structure**

```
build/
├── .github/
│   ├── workflows/build.yml        # Main centralized build workflow
│   └── actions/trigger-build/     # Reusable composite action
├── scripts/                       # Build scripts (shared with local)
├── README.md                      # This file
└── artifacts/                     # Build outputs (generated)
```

---

**🔗 Related Repositories:**
- [Application](../application) - Main calculator application
- [Static Library](../static_library) - Math utilities library  
- [Manifest](../manifest) - Workspace configuration