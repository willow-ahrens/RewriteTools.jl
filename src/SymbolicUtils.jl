module SymbolicUtils

using DocStringExtensions
export @syms, term, showraw, hasmetadata, getmetadata, setmetadata

using TermInterface
using DataStructures
import Base: +, -, *, /, //, \, ^, ImmutableDict
include("types.jl")
export istree, operation, arguments, similarterm

# LinkedList, simplification utilities
include("utils.jl")

# A library for composing expr -> expr functions
include("rewriters.jl")

using Combinatorics: permutations, combinations
export @rule, RuleSet, @capture, @slots

# Rule type and @rule macro
include("rule.jl")

# Matching a Rule
include("matchers.jl")

end # module
