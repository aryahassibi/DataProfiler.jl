<!-- Banner (optional) -->
<p align="center">
  <img src="https://raw.githubusercontent.com/aryahassibi/DataProfiler.jl/main/docs/src/assets/banner.png" alt="DataProfiler.jl banner">
</p>

<h1 align="center">DataProfiler.jl</h1>

<p align="center">
  <a href="https://github.com/aryahassibi/DataProfiler.jl/actions">
    <img src="https://github.com/aryahassibi/DataProfiler.jl/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI">
  </a>
  <a href="https://github.com/aryahassibi/DataProfiler.jl/actions">
    <img src="https://github.com/aryahassibi/DataProfiler.jl/actions/workflows/docs.yml/badge.svg?branch=develop" alt="Docs">
  </a>
  <!-- Add more badges later: 
    coverage, docs-stable, docs-dev, version, etc. 
    -->
</p>


## Overview
**DataProfiler.jl** provides a One-command, human-friendly DataFrame profiler in Julia. Read the full documentation and examples by opening `docs/build/index.html` file in a browser.

It is simply tedious to write the same handful of lines every time you pick up a new dataset—compute summaries, check missingness, inspect distributions, make a few quick plots—all just to get oriented. DataProfiler.jl automates the repetitive early steps in data exploration and helps you focus on the real analysis instead.

Yes, tools like ydata-profiling make this easier in *Python*, but *Julia* has lacked a native alternative.  DataProfiler.jl fills that gap by offering a interface built directly on top of Core Julia, DataFrames, and StatsBase. And because it is written in pure Julia, it can take full advantage of the performance and composability of the Julia ecosystem.

📄 Full documentation is available [here](https://aryahassibi.github.io/DataProfiler.jl).

---

## Installation

The package can be installed with the Julia package manager. From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```
pkg> add https://github.com/aryahassibi/DataProfiler.jl
```

Or, equivalently, via the `Pkg` API:
```julia
julia> import Pkg; Pkg.add("https://github.com/aryahassibi/DataProfiler.jl")
```

DataProfiler.jl supports Julia 1.10 and later.

---

## Quick start

1. Make sure the project is activated (see **Installation**).
2. Start Julia and run the snippet below:

```julia
using DataProfiler, DataFrames, Random
Random.seed!(1)
df = DataFrame(
    a = randn(200),
    b = rand(1:5, 200),
    c = rand(["2025-09-01", "x", "y"], 200),
)
report = profile(df; sample_rows = 150, maxplots = 4)
save_report(report, "report.md")
```

3. Inspect the generated `report.md` (and the ASCII plots embedded inside). Any PNG charts, if CairoMakie is available, are saved to `profile_artifacts/` beside the report.

`CairoMakie` is needed for PNG plots. You can either rely on the ASCII plots, or install `CairoMakie`.
 (`using Pkg; Pkg.add("CairoMakie")`)
 Run `pkg> test` inside the project to verify everything after making changes.

> [!WARNING]
> PNG boxplots need StatsMakie (which may not resolve on Julia 1.11)

---

## Features
- **Data diagnostics:** missingness overview, duplicate detection, semantic hints for ID/date/categorical columns  
- **Numeric analysis:** summary statistics, quantiles, skewness/kurtosis, MAD/IQR outlier detection  
- **Visual summaries:** ASCII histograms and boxplots via UnicodePlots; optional PNG plots via CairoMakie  
- **Non-destructive design:** never mutates input DataFrames; sampling avoids expensive per-column work  
- **Headless-friendly:** plotting and summaries work in scripts, terminals, and CI environments

---

## Development

Active development happens on the `develop` branch. 
Releases are merged into `main` and tagged.

### Local setup

```bash
git clone https://github.com/aryahassibi/DataProfiler.jl.git
cd DataProfiler.jl
julia --project=.
```


```julia
julia> ] instantiate
julia> ] test
```

### Build Docs

```bash
julia --project=docs docs/make.jl
```

---

<h1 align="center">DataProfiler.jl</h1>
<p align="center">Contributions are very welcome! ❤️</p>



