# QMD Setup for Claude Code

QMD (Quick Markdown Search) is now set up for efficient code searching with minimal token usage.

## Installation Complete ✅

- **Location**: `~/bin/qmd/`
- **Index Location**: `~/.cache/qmd/index.sqlite`
- **Bun Runtime**: `~/.bun/bin/bun`

## Collection Created

The `openclaw` collection indexes all Swift files in this project:
- **Pattern**: `**/*.swift`
- **Files Indexed**: 79 files
- **Collection Name**: `openclaw`

## Usage for Claude Code

### 1. Full-Text Search (BM25)
```bash
qmd search "query" -n 5 -c openclaw
```

Example:
```bash
qmd search "DietaryRestriction" -n 3 -c openclaw
qmd search "ModelManager initialize" --full -c openclaw
```

### 2. Get Specific Files
```bash
qmd get <filepath>
qmd get <filepath>:line -l 50
```

Example:
```bash
qmd get openclaw/models/coremodels.swift
qmd get openclaw/app/appstate.swift:20 -l 30
```

### 3. Get Multiple Files
```bash
qmd multi-get "pattern" -l 100
```

Example:
```bash
qmd multi-get "**/*Models.swift"
qmd multi-get "openclaw/skills/**/*.swift" -l 50
```

### 4. List Files in Collection
```bash
qmd ls openclaw
qmd ls openclaw/models
```

### 5. Update Index (After Code Changes)
```bash
qmd update
```

### 6. Check Status
```bash
qmd status
qmd collection list
```

## Advanced Features

### Vector Search (Semantic)
To enable semantic search, create embeddings (this downloads ~300MB model):
```bash
qmd embed
```

Then use:
```bash
qmd vsearch "find all view models"
qmd query "how is persistence handled?"  # Combined search + reranking
```

### Output Formats
- `--json` - JSON output
- `--csv` - CSV output
- `--md` - Markdown output
- `--xml` - XML output
- `--files` - File list only (docid, score, path)
- `--line-numbers` - Add line numbers

### Filtering
- `-c <collection>` - Filter to specific collection
- `--min-score <num>` - Minimum similarity score
- `-n <num>` - Number of results
- `--all` - Return all matches

## PATH Configuration

Add to your `~/.zshrc` (already added):
```bash
export PATH="$HOME/bin/qmd:$HOME/.bun/bin:$PATH"
```

## Benefits for Claude Code

1. **Token Efficiency**: Search returns only relevant code snippets
2. **Fast Lookup**: BM25 search is instant, no API calls needed
3. **Context-Aware**: Get exact lines or snippets instead of full files
4. **Multi-File**: Retrieve multiple related files in one query
5. **Offline**: Works without internet connection

## Example Workflow for Claude

Instead of:
```
Read all Swift files to find where DietaryRestriction is used
```

Use:
```bash
qmd search "DietaryRestriction" -n 10 --files -c openclaw
# Then read only the specific files found
```

## Maintenance

- **Update index**: `qmd update` (run after significant code changes)
- **Clean cache**: `qmd cleanup`
- **Remove collection**: `qmd collection remove openclaw`

## Models (Auto-Downloaded on First Use)

- **Embedding**: embeddinggemma-300M-Q8_0 (~300MB)
- **Reranking**: qwen3-reranker-0.6b-q8_0 (~600MB)
- **Generation**: Qwen3-0.6B-Q8_0 (~600MB)

These are downloaded to `~/.cache/qmd/models/` only if you use `qmd embed` or `qmd vsearch`.

## Integration with Claude Code

Claude Code can now use QMD commands via Bash tool calls:
```typescript
// Instead of reading entire files
Bash("qmd search 'AppState initialization' -c openclaw --full")

// Get specific code sections
Bash("qmd get openclaw/app/appstate.swift:30 -l 40")

// Multi-file retrieval
Bash("qmd multi-get 'openclaw/models/**/*Models.swift' -l 100")
```

This reduces token usage significantly when working with large codebases!
