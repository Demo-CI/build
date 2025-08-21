# Build Summary Action

Generates comprehensive build summaries with metrics, timeline, and results for GitHub Actions.

## Features

- Build configuration and results table
- Performance metrics and timing
- ASCII timeline visualization
- Artifacts and logs information

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

## Key Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `build-type` | Build type (release/debug) | Yes |
| `save-logs` | Whether logs were saved | Yes |
| `artifacts-retention` | Retention period in days | Yes |
| `library-status` | Library build outcome | Yes |
| `application-status` | Application build outcome | Yes |
| `tests-status` | Tests outcome | Yes |
| `metrics-file` | Path to metrics CSV file | Yes |

## Metrics File Format

CSV format expected:
```csv
step,start_time,end_time,duration_seconds,status
build_init,1634567890,1634567920,30,success
workspace_setup,1634567920,1634567980,60,success
```

## Example Output

Generates comprehensive summary including:
- Build configuration table
- Component status (library, application, tests)
- Performance metrics with duration
- ASCII timeline visualization

Requirements: `bc` command for calculations (available in Ubuntu runners)
- Valid step outcomes (success, failure, skipped)
