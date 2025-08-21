# Post Build Results Action

Posts centralized build results as comments to pull requests in source repositories.

## Features

- Comprehensive status reporting (library, application, tests)
- Build metrics and performance data
- Deep links to logs and artifacts
- Rich formatting with emojis and tables

## Usage

```yaml
- name: Post build results to source PR
  if: always() && github.event_name == 'repository_dispatch' && needs.build.outputs.pr-number != ''
  uses: ./.github/actions/post-build-results
  with:
    github-token: ${{ secrets.PAT_TOKEN }}
    source-repo: ${{ needs.build.outputs.source-repo }}
    pr-number: ${{ needs.build.outputs.pr-number }}
    build-type: ${{ needs.build.outputs.build-type }}
    save-logs: ${{ needs.build.outputs.save-logs }}
    build-status: ${{ needs.build.result }}
    library-status: ${{ needs.build.outputs.library-status }}
    application-status: ${{ needs.build.outputs.application-status }}
    tests-status: ${{ needs.build.outputs.tests-status }}
    build-start-time: ${{ needs.build.outputs.build-start-time }}
    artifacts-retention: '5'
```

## Key Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `github-token` | Token with PR comment permissions | Yes |
| `source-repo` | Source repository (owner/repo format) | Yes |
| `pr-number` | Pull request number | Yes |
| `build-type` | Build type (release/debug) | Yes |
| `build-status` | Overall build job status | Yes |
| `library-status` | Library build outcome | Yes |
| `application-status` | Application build outcome | Yes |
| `tests-status` | Tests outcome | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `comment-posted` | Whether comment was posted (true/false) |
| `comment-url` | URL of posted comment (if successful) |

## Example Comment

```markdown
## ✅ Centralized Build Success

**Build Configuration:**
- **Type:** `release`
- **Duration:** `180s (3 min)`
- **Run:** [#42](https://github.com/Demo-CI/build/actions/runs/12345)

**Build Steps:**
- **Static Library:** ✅ Success
- **Application:** ✅ Success  
- **Tests:** ✅ Success

**Artifacts:**
- 📦 Build artifacts available for 5 days
- 📝 Detailed build logs saved

**Actions:**
- [View build logs](https://github.com/Demo-CI/build/actions/runs/12345)
- [Download artifacts](https://github.com/Demo-CI/build/actions/runs/12345)
```
