import StatsBase: sample

const PREVIEW_MAX_ROWS = 5
const PREVIEW_MAX_COLS = 6

function profile(df::DataFrame; sample_rows::Int = 1000, maxplots::Int = 8, outdir::AbstractString = "profile_artifacts", by::Union{Nothing,Vector{Symbol}} = nothing)
    sample_rows >= 1 || throw(ArgumentError("sample_rows must be positive"))
    maxplots >= 0 || throw(ArgumentError("maxplots must be non-negative"))

    nrows = nrow(df)
    ncols = ncol(df)
    sampled = nrows > sample_rows
    actual_sample = sampled ? min(sample_rows, nrows) : nrows
    # Sample rows without replacement when the table is large.
    idx = sampled ? sample(1:nrows, actual_sample; replace = false) : collect(1:nrows)
    df_sample = df[idx, :]

    mkpath(outdir)

    profiles = ColumnProfile[]
    plot_budget = 0
    for name_str in names(df)
        name_sym = Symbol(name_str)
        col = df[!, name_str]
        sample_col = df_sample[!, name_str]
        make_plots = plot_budget < maxplots
        profile = profile_column(col; name = name_sym, sample = sample_col, make_plots = make_plots, plot_dir = outdir)
        push!(profiles, profile)
        if make_plots
            plot_budget += 1
        end
    end

    per_column_missing = Dict(Symbol(name) => missing_summary(df[!, name]) for name in names(df))
    total_missing = sum(summ.nmiss for summ in values(per_column_missing))
    total_cells = nrows * max(ncols, 1)
    overall_missing = Dict(
        :total_missing => total_missing,
        :fraction => total_cells == 0 ? 0.0 : total_missing / total_cells,
        :per_column => per_column_missing
    )

    duplicates = dup_summary(df; by = by)

    preview_rows = min(nrows, PREVIEW_MAX_ROWS)
    preview_cols = min(ncols, PREVIEW_MAX_COLS)
    preview_names = ncols == 0 ? Symbol[] : Symbol.(names(df)[1:preview_cols])
    preview_df = if ncols == 0
        DataFrame()
    else
        select(first(df, preview_rows), preview_names)
    end
    truncated_rows = nrows > preview_rows
    truncated_cols = ncols > preview_cols

    return ProfileReport(
        nrows,
        ncols,
        sampled,
        actual_sample,
        profiles,
        overall_missing,
        duplicates,
        preview_df,
        preview_rows,
        preview_cols,
        truncated_rows,
        truncated_cols,
        outdir
    )
end

"""
    profile(df::DataFrame; sample_rows::Int=1000, maxplots::Int=8, outdir::AbstractString="profile_artifacts", by::Union{Nothing,Vector{Symbol}}=nothing)

Generate a comprehensive data profile of `df`, with optional row sampling, full column profiling, and an assembled report of plots and summaries in a `ProfileReport`.
# Preview

The returned report now includes a head preview (`report.preview`) capped at 5 rows × 6 columns so the generated Markdown can display a compact glimpse of the data.

# Examples

```jldoctest
julia> using DataProfiler, DataFrames

julia> df = DataFrame(a = randn(100), b = rand(1:3, 100));

julia> report = profile(df; sample_rows = 50);

julia> report.sampled
true
```

```jldoctest
julia> using DataProfiler, DataFrames

julia> df = DataFrame(id = repeat(1:3, inner = 2));

julia> profile(df; by = [:id]).duplicates[:duplicate_count]
3
```
"""
profile
