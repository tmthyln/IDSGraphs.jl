# IDSGraphs.jl Documentation
This is a convenience package for reading and processing IDS files, which represent decompositions of CJK (Chinese, Japanese, Korean) language characters. Functionality is provided for the pipeline from reading IDS files to representing them as a graph of character component dependencies.

Still in early development! APIs have yet to be finalized, more basic features will be added, tests are currently non-existent, and documentation is sparse. Development is ongoing. (This is a more generally useful part of my other project [Tong.jl](https://tmthyln.github.io/Tong.jl/), which will likely not be registered as a package due to limited usefulness to others.)

```@contents
```

## Installation
This package can be installed as usual via Pkg:
```julia-repl
julia> ] add IDSGraphs
```
