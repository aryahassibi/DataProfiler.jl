"""
    module DataProfiler

Human-friendly, one-command DataFrame profiling in Julia.

Main entry points:
- `profile` — generate a comprehensive data profile of a table and return a `ProfileReport`.
- `render_markdown`/`save_report` — render/persist the profiling results.
- `profile_column`, `outlier_flags`, `missing_summary`, `dup_summary` — building blocks used by the profiler.
"""

module DataProfiler

using DataFrames
using StatsBase
using UnicodePlots

const _cairo_pkg = Base.find_package("CairoMakie")
const _statsmakie_pkg = Base.find_package("StatsMakie")

@static if _cairo_pkg !== nothing
    using CairoMakie
    const CAIRO_AVAILABLE = true
else
    const CAIRO_AVAILABLE = false
end

@static if _cairo_pkg !== nothing && _statsmakie_pkg !== nothing
    using StatsMakie
    const CAIRO_BOXPLOT_AVAILABLE = true
else
    const CAIRO_BOXPLOT_AVAILABLE = false
end

export profile, profile_column, outlier_flags, save_report, render_markdown, missing_summary, dup_summary

"""
    ColumnProfile

Summary of a single column produced by `profile_column` and used inside `ProfileReport`.

Fields
- `name::Symbol` — column name.
- `eltype_str::String` — element type as a string (pretty-printed eltype).
- `n::Int` — total length of the column.
- `nmiss::Int` — number of missing entries.
- `nunique::Int` — number of unique non-missing values.
- `is_constant::Bool` — whether all non-missing values are identical.
- `is_numeric::Bool` — whether values are numeric (after missing stripping).
- `notes::Vector{String}` — semantic hints (e.g., likely ID, date-like, categorical).
- `stats::Dict{Symbol,Float64}` — numeric summary statistics (mean, std, quantiles…).
- `ascii_hist::String` — ASCII histogram (UnicodePlots) for numeric data.
- `ascii_box::String` — ASCII boxplot (UnicodePlots) for numeric data.
- `png_hist_path::Union{Nothing,String}` — path to PNG histogram if CairoMakie available.
- `png_box_path::Union{Nothing,String}` — path to PNG boxplot if CairoMakie available.
"""
struct ColumnProfile
    name::Symbol
    eltype_str::String
    n::Int
    nmiss::Int
    nunique::Int
    is_constant::Bool
    is_numeric::Bool
    notes::Vector{String}
    stats::Dict{Symbol,Float64}
    ascii_hist::String
    ascii_box::String
    png_hist_path::Union{Nothing,String}
    png_box_path::Union{Nothing,String}
end

"""
    ProfileReport

Top-level result of `profile(df)` that aggregates per-column profiles and dataset-level summaries.

Fields
- `nrows::Int` — number of rows in the profiled `DataFrame`.
- `ncols::Int` — number of columns.
- `sampled::Bool` — whether rows were sampled to limit work/plots.
- `sample_rows::Int` — size of the sample actually used.
- `profiles::Vector{ColumnProfile}` — per-column profiles.
- `overall_missing::Dict{Symbol,Any}` — totals and per-column missingness info.
- `duplicates::Dict{Symbol,Any}` — duplicate summary (row-wise or by keys).
- `preview::DataFrame` — head preview of the data (truncated rows/columns as needed).
- `preview_rows::Int` — number of rows shown in the preview.
- `preview_cols::Int` — number of columns shown in the preview.
- `preview_truncated_rows::Bool` — whether additional rows exist beyond the preview.
- `preview_truncated_cols::Bool` — whether additional columns exist beyond the preview.
- `outdir::String` — directory where artifacts (plots) are written.
"""
struct ProfileReport
    nrows::Int
    ncols::Int
    sampled::Bool
    sample_rows::Int
    profiles::Vector{ColumnProfile}
    overall_missing::Dict{Symbol,Any}
    duplicates::Dict{Symbol,Any}
    preview::DataFrame
    preview_rows::Int
    preview_cols::Int
    preview_truncated_rows::Bool
    preview_truncated_cols::Bool
    outdir::String
end

include("column_profile.jl")
include("plots.jl")
include("report.jl")
include("profile.jl")

end
