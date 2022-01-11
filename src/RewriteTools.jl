module RewriteTools

export @syms, term, showraw, hasmetadata, getmetadata, setmetadata

using TermInterface
import Base: +, -, *, /, //, \, ^, ImmutableDict
include("types.jl")
export istree, operation, arguments, similarterm

# LinkedList, simplification utilities
include("utils.jl")

# A library for composing expr -> expr functions
include("rewriters.jl")

export @rule, RuleSet, @capture, @slots

# Rule type and @rule macro
include("rule.jl")

# Matching a Rule
include("matchers.jl")

end # module
