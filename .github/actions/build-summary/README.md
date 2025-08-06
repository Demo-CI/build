# Build Summary Action

A composite action that generates a comprehensive build summary with metrics, timeline, and results for GitHub Actions workflows.

## Features

- 📊 **Build Configuration Table**: Shows build type, logs, artifacts retention, and trigger information
- 📈 **Build Results**: Status of library, application, and tests with clear visual indicators
- ⏱️ **Performance Metrics**: Detailed timing information for each build step
- 📉 **Build Timeline**: ASCII timeline showing step execution sequence and duration
- 📦 **Artifacts Information**: Details about available artifacts and logs

## Usage

```yaml
- name: Generate build summary
  uses: ./.github/actions/build-summary
  with:
    build-type: ${{ inputs.build_type }}
    save-logs: ${{ inputs.save_logs }}
    artifacts-retention: ${{ inputs.artifacts_retention }}
    trigger-reason: ${{ inputs.trigger_reason }}
    build-start-time: ${{ steps.metrics-init.outputs.build_start_time }}
    source-repo: ${{ inputs.source_repo }}
    source-ref: ${{ inputs.source_ref }}
    source-sha: ${{ inputs.source_sha }}
    library-status: ${{ steps.build-library.outcome }}
    application-status: ${{ steps.build-application.outcome }}
    tests-status: ${{ steps.run-tests.outcome }}
    metrics-file: ${{ steps.metrics-init.outputs.metrics_file }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `build-type` | Build type (release/debug) | Yes | - |
| `save-logs` | Whether logs were saved as artifacts | Yes | - |
| `artifacts-retention` | Artifacts retention period in days | Yes | - |
| `trigger-reason` | Reason for the build trigger | Yes | - |
| `build-start-time` | Build start timestamp (Unix seconds) | Yes | - |
| `source-repo` | Source repository (if applicable) | No | `unknown` |
| `source-ref` | Source branch/ref (if applicable) | No | `unknown` |
| `source-sha` | Source SHA (if applicable) | No | `unknown` |
| `library-status` | Library build step outcome | Yes | - |
| `application-status` | Application build step outcome | Yes | - |
| `tests-status` | Tests step outcome | Yes | - |
| `metrics-file` | Path to the metrics CSV file | Yes | - |

## Outputs

| Output | Description |
|--------|-------------|
| `summary-generated` | Whether the summary was successfully generated |

## Metrics File Format

The action expects a CSV file with the following format:
```csv
step,start_time,end_time,duration_seconds,status
build_init,1634567890,1634567920,30,success
workspace_setup,1634567920,1634567980,60,success
```

## Example Output

The action generates a comprehensive summary in the GitHub Actions step summary, including:

### 🔧 Build Configuration
| Setting | Value |
|---------|-------|
| Build Type | `release` |
| Verbose Logs | `false` |
| Artifacts Retention | `5 days` |

### 📊 Build Results
| Component | Status |
|-----------|--------|
| Static Library | ✅ Built |
| Application | ✅ Built |
| Tests | ✅ Passed |

### ⏱️ Performance Metrics
| Step | Duration | Status |
|------|----------|--------|
| Build Init | 5s | ✅ success |
| Workspace Setup | 45s | ✅ success |

### 📈 Build Timeline
```
Build Timeline (seconds from start):

build init         [  0s ->   5s] (5s) ✓
workspace setup    [  5s ->  50s] (45s) ✓
```

## Requirements

- `bc` command for mathematical calculations (usually available in Ubuntu runners)
- Proper metrics file format as input
- Valid step outcomes (success, failure, skipped)
