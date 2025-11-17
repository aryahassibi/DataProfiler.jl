using Test
using DataProfiler
using DataFrames

@testset "Column profiling" begin
    df = DataFrame(
        num = vcat(collect(1.0:1.0:40.0), [500.0]),
        cat = repeat(["2025-09-01", "x", "y"], inner = 14)[1:41],
        miss = [missing for _ in 1:41]
    )
    df[!, :dupkey] = repeat([1, 2, 3, 4, 5], inner = 9)[1:41]
    push!(df, df[1, :])

    mask = outlier_flags(df.num)
    @test count(identity, mask) == 1
    @test findall(mask) == [41]

    miss_info = missing_summary(df.miss)
    @test miss_info.nmiss == nrow(df)
    @test miss_info.frac == 1.0
    @test length(miss_info.first_positions) == 1

    dup = dup_summary(df)
    @test dup[:duplicate_count] > 0

    dup_by = dup_summary(df; by = [:dupkey])
    @test dup_by[:duplicate_count] > 0
    @test haskey(dup_by, :frequency)

    prof = profile_column(df.cat; name = :cat)
    @test !isempty(prof.notes)
    @test prof.n == nrow(df)

    numeric_profile = profile_column(df.num; name = :num)
    @test haskey(numeric_profile.stats, :mean)
    @test isa(numeric_profile.stats[:mean], Float64)
end

@testset "Profile orchestration" begin
    df = DataFrame(
        a = [1, 2, 3, 4, 100],
        b = ["a", "b", "b", "c", "2025-09-01"],
        c = [missing, 1, missing, 2, 3]
    )
    report = profile(df; sample_rows = 3, maxplots = 2, outdir = joinpath(pwd(), "profile_artifacts_test"))
    @test isa(report, DataProfiler.ProfileReport)
    @test report.nrows == 5
    @test length(report.profiles) == ncol(df)
    @test size(report.preview, 1) == min(nrow(df), 5)
    @test size(report.preview, 2) == min(ncol(df), 6)
    @test report.preview_truncated_rows == false
    @test report.preview_truncated_cols == false
    md = render_markdown(report)
    @test occursin("Data Profile Report", md)
    @test occursin("## Data Preview", md)

    tmp_md = joinpath(pwd(), "profile_test.md")
    save_report(report, tmp_md)
    @test isfile(tmp_md)
    rm(tmp_md; force = true)
    if isdir(report.outdir)
        rm(report.outdir; recursive = true, force = true)
    end
end

@testset "Preview truncation" begin
    df = DataFrame()
    for i in 1:7
        df[!, Symbol("c" * string(i))] = collect(1:8) .+ i
    end
    report = profile(df; sample_rows = 8, maxplots = 0, outdir = joinpath(pwd(), "profile_artifacts_test"))
    @test report.preview_rows == 5
    @test report.preview_cols == 6
    @test report.preview_truncated_rows
    @test report.preview_truncated_cols
    @test size(report.preview, 1) == 5
    @test size(report.preview, 2) == 6
    if isdir(report.outdir)
        rm(report.outdir; recursive = true, force = true)
    end
end
