# Demo-CI Centralized Build System

[![Multi-Repository Build](https://github.com/Demo-CI/build/actions/workflows/build.yml/badge.svg)](https://github.com/Demo-CI/build/actions/workflows/build.yml)

Centralized build system for the Demo-CI multi-repository C++ project with automated PR feedback.

## System Overview

Coordinates building and testing across:
- **[application](../application)** - C++ calculator application  
- **[static_library](../static_library)** - Calculator math utilities library
- **[manifest](../manifest)** - Workspace configuration

### Features
- Automated multi-repository builds
- JSON comment triggers for custom builds
- Automatic PR feedback with results
- Manifest-based workspace consistency

## Build Triggers

### Automatic
- Pull Requests in application/static_library repos
- Push to main/develop branches

### JSON Comments
Post in any PR to customize builds:

```json
{
  "build_type": "debug",
  "save_logs": true,
  "reason": "Testing new feature"
}
```

**Parameters:**
- `build_type`: `"release"` (default) | `"debug"`
- `save_logs`: `true` | `false` (default)
- `reason`: Custom description (optional)

### Manual
[Actions](../../actions) → "Multi-Repository Build" → "Run workflow"

## Setup Requirements

### PAT Token
Configure Personal Access Token for cross-repository triggering:

1. **Create PAT**: GitHub Settings → Developer settings → Personal access tokens
   - Permissions: `repo`, `workflow`
2. **Add to Organization**: Add as `PAT_TOKEN` secret in organization settings
3. **Why needed**: Default `GITHUB_TOKEN` cannot dispatch to other repositories

## Local Development

```bash
# Setup workspace
./scripts/setup-workspace.sh ~/my-workspace
cd ~/my-workspace/build

# Build and test
./scripts/build.sh build
./scripts/build.sh test
```

## Monitoring

- **Status**: [Actions tab](../../actions) or badge above
- **Logs**: Available in workflow run details  
- **Artifacts**: Downloadable from completed runs
- **PR Feedback**: Automatic comments with results

---
**Related:** [Application](../application) | [Static Library](../static_library) | [Manifest](../manifest)