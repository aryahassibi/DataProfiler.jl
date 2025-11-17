using Markdown
using DataFrames

_escape_cell(x) = replace(string(x), '|' => "\\|")

function _preview_markdown(df::DataFrame)
    if ncol(df) == 0
        return "No columns available for preview."
    end
    if nrow(df) == 0
        return "No rows available for preview."
    end
    colnames = names(df)
    header_cells = String["Row"]
    append!(header_cells, ["`" * String(name) * "`" for name in colnames])
    io = IOBuffer()
    println(io, "| ", join(header_cells, " | "), " |")
    println(io, "| ", join(fill("---", length(header_cells)), " | "), " |")
    for (i, row) in enumerate(eachrow(df))
        values = [_escape_cell(row[name]) for name in colnames]
        println(io, "| ", join([string(i); values], " | "), " |")
    end
    return String(take!(io))
end

function _preview_note(report::ProfileReport)
    notes = String[]
    if report.preview_truncated_rows
        push!(notes, "showing first $(report.preview_rows) of $(report.nrows) rows")
    end
    if report.preview_truncated_cols
        push!(notes, "showing first $(report.preview_cols) of $(report.ncols) columns")
    end
    return isempty(notes) ? "" : "*Note:* " * join(notes, "; ") * "."
end

function _format_stats(stats::Dict{Symbol,Float64})
    if isempty(stats)
        return "No numeric stats available"
    end
    io = IOBuffer()
    println(io, "| Metric | Value |")
    println(io, "| --- | --- |")
    for key in sort(collect(keys(stats)))
        println(io, "| ", String(key), " | ", round(stats[key]; digits = 4), " |")
    end
    return String(take!(io))
end

function render_markdown(report::ProfileReport)
    io = IOBuffer()
    println(io, "# Data Profile Report")
    println(io, "\n- Rows: ", report.nrows)
    println(io, "- Columns: ", report.ncols)
    println(io, "- Sampled: ", report.sampled ? "yes" : "no")
    if report.sampled
        println(io, "- Sample size: ", report.sample_rows)
    end

    println(io, "\n## Data Preview")
    preview_md = _preview_markdown(report.preview)
    println(io, "\n", preview_md)
    note = _preview_note(report)
    if !isempty(note)
        println(io, "\n", note)
    end

    overall_missing = report.overall_missing
    println(io, "\n## Missingness Overview")
    println(io, "Total missing: ", overall_missing[:total_missing])
    println(io, " (", round(overall_missing[:fraction] * 100; digits = 2), "%)")
    println(io, "\n| Column | Missing | Fraction | First Missing Runs |")
    println(io, "| --- | --- | --- | --- |")
    for (name, summ) in overall_missing[:per_column]
        frac_pct = round(summ.frac * 100; digits = 2)
        runs = isempty(summ.first_positions) ? "-" : join(summ.first_positions, ", ")
        println(io, "| `", String(name), "` | ", summ.nmiss, " | ", frac_pct, "% | ", runs, " |")
    end

    dup = report.duplicates
    println(io, "\n## Duplicate Rows")
    println(io, "Mode: ", Symbol(dup[:mode]))
    println(io, "\nDuplicates detected: ", dup[:duplicate_count])
    if haskey(dup, :indices) && !isempty(dup[:indices])
        println(io, " (first indices: ", join(dup[:indices], ", "), ")")
    end
    if haskey(dup, :frequency) && nrow(dup[:frequency]) > 0
        println(io, "\n### Duplicate Key Frequencies")
        freq_df = dup[:frequency]
        println(io, "| Keys | Count |")
        println(io, "| --- | --- |")
        for row in eachrow(freq_df)
            keys = [String(row[col]) for col in names(freq_df) if col != :count]
            println(io, "| ", join(keys, ", "), " | ", row[:count], " |")
        end
    end

    println(io, "\n## Columns")
    for profile in report.profiles
        println(io, "\n### `", String(profile.name), "`")
        println(io, "- Type: ", profile.eltype_str)
        println(io, "- Non-missing: ", profile.n - profile.nmiss, " / ", profile.n)
        println(io, "- Unique: ", profile.nunique)
        println(io, "- Constant: ", profile.is_constant)
        if !isempty(profile.notes)
            println(io, "- Notes: ", join(profile.notes, "; "))
        end
        println(io, "\n", _format_stats(profile.stats))
        if !isempty(profile.ascii_hist)
            println(io, "\n```\n", profile.ascii_hist, "\n```")
        end
        if !isempty(profile.ascii_box)
            println(io, "\n```\n", profile.ascii_box, "\n```")
        end
        if profile.png_hist_path !== nothing
            println(io, "\n![Histogram](", profile.png_hist_path, ")")
        end
        if profile.png_box_path !== nothing
            println(io, "\n![Boxplot](", profile.png_box_path, ")")
        end
    end

    return String(take!(io))
end

function save_report(report::ProfileReport, path::AbstractString; fmt::Symbol = :auto)
    format = fmt == :auto ? _format_from_path(path) : fmt
    markdown = render_markdown(report)
    if format == :md
        open(path, "w") do io
            write(io, markdown)
        end
    elseif format == :html
        md = Markdown.parse(markdown)
        html = repr("text/html", md)
        open(path, "w") do io
            write(io, "<!DOCTYPE html>\n<html><head><meta charset=\"utf-8\"><title>Data Profile Report</title></head><body>")
            write(io, html)
            write(io, "</body></html>")
        end
    else
        throw(ArgumentError("Unsupported format: " * String(format)))
    end
    return nothing
end

function _format_from_path(path::AbstractString)
    if endswith(lowercase(path), ".md")
        return :md
    elseif endswith(lowercase(path), ".html")
        return :html
    else
        return :md
    end
end

"""
    render_markdown(report::ProfileReport)

Create a Markdown string summarising the provided `ProfileReport`, including overall dataset notes and per-column sections with plots when available.

# Examples

```jldoctest
julia> using DataProfiler, DataFrames

julia> df = DataFrame(x = 1:3);

julia> report = profile(df);

julia> markdown = render_markdown(report);

julia> occursin("## Data Preview", markdown)
true
```

```jldoctest
julia> using DataProfiler, DataFrames

julia> report = profile(DataFrame(x = [missing, 1, 2]));

julia> render_markdown(report) |> isempty
false
```
"""
render_markdown

"""
    save_report(report::ProfileReport, path::AbstractString; fmt::Symbol=:auto)

Persist an pr to disk as Markdown or HTML. When `fmt == :auto` the file extension decides the output format.

# Examples

```jldoctest
julia> using DataProfiler, DataFrames

julia> report = profile(DataFrame(x = randn(20)));

julia> save_report(report, "report.md")

julia> isfile("report.md")
true
```

```jldoctest
julia> using DataProfiler, DataFrames

julia> report = profile(DataFrame(x = randn(20)));

julia> save_report(report, "report.html")

julia> isfile("report.html")
true
```
"""
save_report
