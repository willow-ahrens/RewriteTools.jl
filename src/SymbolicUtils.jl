"""
$(DocStringExtensions.README)
"""
module SymbolicUtils

using DocStringExtensions
export @syms, term, showraw, hasmetadata, getmetadata, setmetadata

using TermInterface
using DataStructures
using Setfield
import Setfield: PropertyLens
import Base: +, -, *, /, //, \, ^, ImmutableDict
using ConstructionBase
include("types.jl")
export istree, operation, arguments, similarterm

# LinkedList, simplification utilities
include("utils.jl")

export Rewriters

# A library for composing together expr -> expr functions
include("rewriters.jl")

using .Rewriters

using Combinatorics: permutations, combinations
export @rule, RuleSet, @capture, @slots

# Rule type and @rule macro
include("rule.jl")

# Matching a Rule
include("matchers.jl")

end # module
