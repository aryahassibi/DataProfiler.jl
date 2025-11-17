# DataProfiler.jl

Generate a full data profile for a `DataFrame` in one function call, producing a compact, human-readable report (Markdown or HTML) with stat and plots.

## Quickstart

```julia
julia> using Pkg
julia> Pkg.activate("./DataProfiler"); Pkg.instantiate()

julia> using DataProfiler, DataFrames
julia> df = DataFrame(a = randn(200), b = rand(1:5, 200));

julia> report = profile(df; sample_rows = 150, maxplots = 4);

julia> save_report(report, "report.md")
```

## Features
- Missingness and duplicate summaries
- Numeric stats (mean, std, quantiles, skewness, kurtosis)
- ASCII histograms/boxplots via UnicodePlots; optional PNG via CairoMakie
- Automatic head preview (5×6) at the top of each report
- Semantic hints for string/date/categorical columns

## API
See the [API](@ref) page for full docstrings with examples.
