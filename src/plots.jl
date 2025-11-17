import StatsBase: countmap

function _clean_numeric_for_plot(x::AbstractVector)
    data = Float64[]
    for val in x
        if ismissing(val)
            continue
        elseif val isa Real && isfinite(val)
            push!(data, float(val))
        end
    end
    return data
end

function ascii_histogram(x::AbstractVector)
    data = _clean_numeric_for_plot(x)
    if length(data) < 2
        return ""
    end
    hist = UnicodePlots.histogram(data; nbins = min(20, max(5, round(Int, sqrt(length(data))))))
    return sprint(show, hist)
end

function ascii_box(x::AbstractVector)
    data = _clean_numeric_for_plot(x)
    if length(data) < 2
        return ""
    end
    box = UnicodePlots.boxplot(data)
    return sprint(show, box)
end

function ascii_categorical(x::AbstractVector)
    clean = [String(v) for v in x if !ismissing(v)]
    if isempty(clean)
        return ""
    end
    counts = countmap(clean)
    ordered = sort(collect(counts); by = x -> (-x[2], x[1]))
    top = first(ordered, min(10, length(ordered)))
    max_count = maximum(count for (_, count) in top)
    io = IOBuffer()
    for (label, count) in top
        bar_len = max_count == 0 ? 0 : Int(clamp(round(20 * count / max_count), 1, 20))
        println(io, rpad(label, 15), "|", repeat('#', bar_len), " ", count)
    end
    return String(take!(io))
end

function _sanitize_filename(name::AbstractString)
    cleaned = replace(name, r"\s+" => "_")
    return cleaned
end

function png_histogram(x::AbstractVector, name::AbstractString, outdir::AbstractString)
    if !CAIRO_AVAILABLE
        return nothing
    end
    data = _clean_numeric_for_plot(x)
    if length(data) < 2
        return nothing
    end
    mkpath(outdir)
    fig = CairoMakie.Figure(; size = (600, 400))
    ax = CairoMakie.Axis(fig[1, 1]; title = string(name))
    CairoMakie.hist!(ax, data; bins = min(20, max(5, round(Int, sqrt(length(data))))))
    path = joinpath(outdir, _sanitize_filename(string(name)) * "_hist.png")
    CairoMakie.save(path, fig)
    return path
end

function png_boxplot(x::AbstractVector, name::AbstractString, outdir::AbstractString)
    if !CAIRO_AVAILABLE || !CAIRO_BOXPLOT_AVAILABLE
        return nothing
    end
    data = _clean_numeric_for_plot(x)
    if length(data) < 2
        return nothing
    end
    mkpath(outdir)
    fig = CairoMakie.Figure(; size = (400, 400))
    ax = CairoMakie.Axis(fig[1, 1]; title = string(name))
    StatsMakie.boxplot!(ax, data)
    path = joinpath(outdir, _sanitize_filename(string(name)) * "_box.png")
    CairoMakie.save(path, fig)
    return path
end
