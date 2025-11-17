import StatsBase: mad, skewness, kurtosis, quantile
using Statistics: mean, std, median
using Base.Iterators: take

const _DATE_HINT = r"\b\d{4}-\d{2}-\d{2}\b"

_missing_type(::Type{T}) where {T} = T
_missing_type(::Type{Union{Missing,T}}) where {T} = T

_is_numeric_type(::Type{T}) where {T<:Real} = true
_is_numeric_type(::Type{Union{Missing,T}}) where {T<:Real} = true
_is_numeric_type(::Type) = false

function _notes_for_strings(values::Vector, nunique::Int, n::Int)
    notes = String[]
    if n == 0
        return notes
    end
    if nunique > 0.9 * n
        lengths = [length(String(v)) for v in take((v for v in values if !ismissing(v)), min(n, 50))]
        if !isempty(lengths) && mean(lengths) > 8
            push!(notes, "likely identifier (high-cardinality strings)")
        end
    end
    if any(!ismissing(v) && occursin(_DATE_HINT, String(v)) for v in take(values, min(n, 200)))
        push!(notes, "contains date-like strings (YYYY-MM-DD)")
    end
    if nunique <= 50 && nunique / max(n, 1) <= 0.05
        push!(notes, "possible categorical feature")
    end
    return notes
end

function missing_summary(x::AbstractVector)
    n = length(x)
    miss_idx = findall(ismissing, x)
    frac = n == 0 ? 0.0 : length(miss_idx) / n
    runs = Int[]
    if !isempty(miss_idx)
        last_seen = miss_idx[1] - 1
        for (i, idx) in pairs(miss_idx)
            if i == 1 || idx != last_seen + 1
                push!(runs, idx)
                if length(runs) >= 5
                    break
                end
            end
            last_seen = idx
        end
    end
    return (; nmiss = length(miss_idx), frac = frac, first_positions = runs)
end

function dup_summary(df::DataFrame; by::Union{Nothing,Vector{Symbol}} = nothing)
    if by === nothing
        mask = nonunique(df)
        idx = findall(mask)
        return Dict(
            :mode => :row,
            :duplicate_count => length(idx),
            :indices => idx[1:min(end, 5)]
        )
    else
        mask = nonunique(df, by)
        idx = findall(mask)
        freq = isempty(idx) ? DataFrame() : combine(groupby(df[mask, :], by), nrow => :count)
        return Dict(
            :mode => :by,
            :keys => by,
            :duplicate_count => length(idx),
            :indices => idx[1:min(end, 5)],
            :frequency => freq
        )
    end
end

function outlier_flags(x::AbstractVector{<:Real}; method::Symbol = :mad, z::Real = 3.5)
    mask = falses(length(x))
    finite_idx = Int[]
    finite_vals = Float64[]
    for (i, val) in pairs(x)
        if ismissing(val) || !isfinite(val)
            continue
        end
        push!(finite_idx, i)
        push!(finite_vals, float(val))
    end
    if length(finite_vals) < 2
        return mask
    end
    if method === :mad
        center = median(finite_vals)
        scale = mad(finite_vals; center = center, normalize = false)
        if scale == 0
            return mask
        end
        for (idx, value) in zip(finite_idx, finite_vals)
            if abs(value - center) / scale > z
                mask[idx] = true
            end
        end
    elseif method === :iqr
        q25, q75 = quantile(finite_vals, (0.25, 0.75))
        spread = q75 - q25
        if spread == 0
            return mask
        end
        lower = q25 - z * spread
        upper = q75 + z * spread
        for (idx, value) in zip(finite_idx, finite_vals)
            if value < lower || value > upper
                mask[idx] = true
            end
        end
    else
        throw(ArgumentError("Unsupported method $(method). Use :mad or :iqr."))
    end
    return mask
end

function _numeric_stats(values::Vector{Float64})
    if length(values) < 2
        return Dict{Symbol,Float64}()
    end
    sorted_vals = sort(values)
    q25, med, q75 = quantile(sorted_vals, (0.25, 0.5, 0.75))
    stats = Dict{Symbol,Float64}(
        :mean => mean(values),
        :std => std(values),
        :min => sorted_vals[1],
        :q25 => q25,
        :median => med,
        :q75 => q75,
        :max => sorted_vals[end]
    )
    if length(values) >= 3
        stats[:skew] = skewness(values)
        stats[:kurt] = kurtosis(values)
    end
    return stats
end

function _collect_numeric(x::AbstractVector{T}) where {T<:Real}
    cleaned = Float64[]
    for val in x
        if ismissing(val) || !isfinite(val)
            continue
        end
        push!(cleaned, float(val))
    end
    return cleaned
end

function _collect_numeric(x::AbstractVector)
    cleaned = Float64[]
    for val in x
        if ismissing(val)
            continue
        elseif val isa Real && isfinite(val)
            push!(cleaned, float(val))
        end
    end
    return cleaned
end

function _profile_notes(x::Vector, nunique::Int, n::Int, is_numeric::Bool, is_categorical::Bool)
    if is_numeric
        return String[]
    else
        notes = _notes_for_strings(x, nunique, n)
        if is_categorical
            push!(notes, "marked as categorical")
        end
        return notes
    end
end

function profile_column(x::AbstractVector{<:Real}; name::Symbol, is_categorical::Bool = false, sample::Union{Nothing,AbstractVector} = nothing, make_plots::Bool = true, plot_dir::Union{Nothing,String} = nothing)
    return _build_profile(collect(x); name = name, is_numeric = true, is_categorical = is_categorical, sample = sample, make_plots = make_plots, plot_dir = plot_dir)
end

function profile_column(x::AbstractVector; name::Symbol, is_categorical::Bool = false, sample::Union{Nothing,AbstractVector} = nothing, make_plots::Bool = true, plot_dir::Union{Nothing,String} = nothing)
    numeric_flag = _is_numeric_type(eltype(x))
    return _build_profile(collect(x); name = name, is_numeric = numeric_flag, is_categorical = is_categorical, sample = sample, make_plots = make_plots, plot_dir = plot_dir)
end

function _build_profile(x::Vector; name::Symbol, is_numeric::Bool, is_categorical::Bool, sample::Union{Nothing,AbstractVector}, make_plots::Bool, plot_dir::Union{Nothing,String})
    n = length(x)
    nmiss = count(ismissing, x)
    clean_values = collect(skipmissing(x))
    nunique = length(unique(clean_values))
    is_constant = nunique <= 1 && nmiss < n
    eltype_str = string(eltype(x))

    notes = _profile_notes(x, nunique, n, is_numeric, is_categorical)
    stats = Dict{Symbol,Float64}()
    hist_text = ""
    box_text = ""
    png_hist = nothing
    png_box = nothing

    if is_numeric
        sample_vec = isnothing(sample) ? x : collect(sample)
        numeric_full = _collect_numeric(x)
        stats = _numeric_stats(numeric_full)
        if make_plots
            hist_text = ascii_histogram(sample_vec)
            box_text = ascii_box(sample_vec)
            if CAIRO_AVAILABLE && !isnothing(plot_dir)
                png_hist = png_histogram(sample_vec, String(name), plot_dir)
                png_box = png_boxplot(sample_vec, String(name), plot_dir)
            end
        end
    else
        if make_plots && nunique > 0 && nunique <= 30
            sample_vec = isnothing(sample) ? x : collect(sample)
            hist_text = ascii_categorical(sample_vec)
        end
    end

    return ColumnProfile(
        name,
        eltype_str,
        n,
        nmiss,
        nunique,
        is_constant,
        is_numeric,
        notes,
        stats,
        hist_text,
        box_text,
        png_hist,
        png_box
    )
end

"""
    missing_summary(x::AbstractVector)

Summarise missing entries in `x`.

Returns a named tuple with the count of missings, their fraction, and the starting indices of the first few missing runs.

# Examples

```jldoctest
julia> using DataProfiler

julia> missing_summary([1, missing, 2, missing, missing])
(nmiss = 3, frac = 0.6, first_positions = [2, 4])

julia> missing_summary(Int[])
(nmiss = 0, frac = 0.0, first_positions = Int64[])
```
"""
missing_summary

"""
    dup_summary(df::DataFrame; by::Union{Nothing,Vector{Symbol}}=nothing)

Report duplicate rows in `df`. When `by` is provided, duplicates are detected only with respect to those keys and a compact frequency table is returned.

# Examples

```jldoctest
julia> using DataProfiler, DataFrames

julia> df = DataFrame(id = [1, 1, 2], value = ["a", "a", "b"]);

julia> summary = dup_summary(df);

julia> summary[:duplicate_count]
1

julia> summary[:indices]
1-element Vector{Int64}:
 2

julia> dup_summary(df; by = [:id])[:duplicate_count]
1
```
"""
dup_summary

"""
    outlier_flags(x::AbstractVector{<:Real}; method::Symbol=:mad, z::Real=3.5)

Return a boolean mask that marks outliers in `x` using either the MAD or IQR rules. Missings and non-finite values are ignored.

# Examples

```jldoctest
julia> using DataProfiler

julia> x = [1, 1, 2, 2, 100];

julia> outlier_flags(x)
5-element BitVector:
 0
 0
 0
 0
 1

julia> outlier_flags(x; method = :iqr, z = 1.5)
5-element BitVector:
 0
 0
 0
 0
 1
```
"""
outlier_flags

"""
    profile_column(x::AbstractVector; name::Symbol, is_categorical::Bool=false)

Compute a `ColumnProfile` with type information, summary statistics, semantic hints, and optional plots for the supplied column vector.

# Examples

```jldoctest
julia> using DataProfiler, DataFrames

julia> df = DataFrame(a = [1, 2, 3, missing], b = ["2024-01-01", "a", "b", "c"]);

julia> profile = profile_column(df.a; name = :a);

julia> profile.stats[:mean]
2.0

julia> profile_column(df.b; name = :b).notes
1-element Vector{String}:
 "contains date-like strings (YYYY-MM-DD)"
```
"""
profile_column
