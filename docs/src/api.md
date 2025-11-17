# API Reference

This page lists the public API and links to full docstrings with examples. The quick list below is readable even without building the docs.

## Public API (quick list)
- `profile(df; sample_rows=1000, maxplots=8, outdir="profile_artifacts", by=nothing)` — generate a comprehensive data profile and return a `ProfileReport`.
- `render_markdown(report)` — render a profile report as Markdown text.
- `save_report(report, path; fmt=:auto)` — write Markdown or HTML to disk.
- `profile_column(x; name::Symbol, is_categorical=false)` — build a `ColumnProfile` for one column.
- `outlier_flags(x; method=:mad, z=3.5)` — boolean mask of numeric outliers (MAD or IQR).
- `missing_summary(x)` — count and fraction of missings plus first run starts.
- `dup_summary(df; by=nothing)` — duplicate rows summary (optionally by keys).

Types
- `ProfileReport` — top-level profiling result with dataset and column summaries.
- `ColumnProfile` — per-column profile with stats, notes, and plots.
  - Includes `preview` plus metadata about truncated rows/columns for quick table heads.

## Full Docstrings

```@autodocs
Modules = [DataProfiler]
Order = [:module, :type, :function]
```
