using LightGraphs
import LightGraphs: add_vertex!, add_edge!, SimpleDiGraph
using Pkg.Artifacts

# Dependency graph struct creation
# --------------------------------
struct DependencyGraph
    graph::SimpleDiGraph{UInt32}
    mapping::Dict{Char, UInt32}
    reverse_mapping::Vector{Char}
    structures::Dict{Char, CharStructure}
end
DependencyGraph() = DependencyGraph(
        SimpleDiGraph{UInt32}(),
        Dict{Char, UInt32}(),
        Vector{Char}(),
        Dict{Char, CharStructure}())

function LightGraphs.add_vertex!(dep::DependencyGraph, vertex::Char)
    if !haskey(dep.mapping, vertex)
        add_vertex!(dep.graph)
        dep.mapping[vertex] = nv(dep.graph)
        push!(dep.reverse_mapping, vertex)
    end
    nothing
end

function LightGraphs.add_edge!(dep::DependencyGraph, from::Char, to::Char)
    add_vertex!(dep, from)
    add_vertex!(dep, to)
    add_edge!(dep.graph, dep.mapping[from], dep.mapping[to])
    nothing
end

function add_structure!(dep::DependencyGraph, vertex::Char, structure::CharStructure)
    dep.structures[vertex] = structure
    nothing
end

Base.getindex(dep::DependencyGraph, char::Char) = dep.structures[char]
Base.length(dep::DependencyGraph) = nv(dep.graph)
LightGraphs.nv(dep::DependencyGraph) = nv(dep.graph)

function load_dependency_graph()
    # artifact management
    artifact_toml = joinpath(@__DIR__, "Artifacts.toml")
    ids_hash = artifact_hash("ids", artifact_toml)

    if ids_hash === nothing || !artifact_exists(ids_hash)
        ids_hash = create_artifact() do artifact_dir
            ids_url = "https://raw.githubusercontent.com/cjkvi/cjkvi-ids/master/ids.txt"
            download(ids_url, joinpath(artifact_dir, "ids.txt"))
        end

        bind_artifact!(artifact_toml, "ids", ids_hash)
    end

    file = joinpath(artifact_path(ids_hash), "ids.txt")

    pattern = r"^[^\s]+\s+([^\s])\s+(.+)$"

    dep = DependencyGraph()

    for line in eachline(file)
        startswith(line, "#") && continue

        m = match(pattern, line)
        m === nothing && continue
        char_str, ids_string = m.captures
        char = first(char_str)

        add_vertex!(dep, char)
        for component in filter(c -> c ∉ range('⿰', '⿻', step = 1) && c != char, ids_string)
            add_edge!(dep, component, char)
        end
        dep.structures[char] = parse(ids_string)
    end

    dep
end

# Functions on dependency graphs
# ------------------------------
components(dep::DependencyGraph, char::Char) =
    (dep.reverse_mapping[code] for code in inneighbors(dep.graph, dep.mapping[char]))

compounds(dep::DependencyGraph, char::Char) =
    (dep.reverse_mapping[code] for code in outneighbors(dep.graph, dep.mapping[char]))

function subgraph(dep::DependencyGraph, condition)
    vlist = [v for v in vertices(dep.graph) if condition(v)]
    length(vlist) == 0 && return DependencyGraph()
    sg, vmap = induced_subgraph(dep.graph, vlist)

    reverse_mapping = [dep.reverse_mapping[vmap[sg_code]] for sg_code in 1:length(vlist)]
    mapping = Dict(char => sg_code for (sg_code, char) in enumerate(reverse_mapping))
    structures = Dict(char => structure for (char, structure) in dep.structures if haskey(mapping, char))

    DependencyGraph(sg, mapping, reverse_mapping, structures)
end

topological_sort(dep::DependencyGraph) =
    (dep.reverse_mapping[code] for code in LightGraphs.Traversals.topological_sort(dep.graph))
