package ast


Pattern :: struct {
    using base_node: Node, // this is `base` or `super` in OOP
	pattern_variant: Any_Pattern,
}


Any_Pattern :: union {
    ^Bad_Pattern,
    ^Wildcard_Pattern,
    ^Literal_Pattern,
    ^Ident_Pattern,
    ^List_Pattern,
    ^Tuple_Pattern,
    ^Record_Pattern,
    ^Constructed_Pattern,
    ^Infix_Pattern,
    ^Typed_Pattern,
    ^Layered_Pattern,
}

connect_pattern :: proc(base: ^Pattern, variant: Any_Pattern) {
    base.pattern_variant = variant
    connect_node(&base.base_node, base)
}


// Patternessions

Bad_Pattern :: struct {
	using base_pattern: Pattern,
}
new_bad_pattern :: proc(base: Node) -> ^Bad_Pattern {
    bad := new(Bad_Pattern)
    bad ^= { base_node=base }
    connect(&bad.base_pattern, bad)
    return bad
}

Wildcard_Pattern :: struct {
	using base_pattern: Pattern,
}

Literal_Pattern :: struct {
	using base_pattern: Pattern,
	value: Literal_Value,
}

Ident_Pattern :: struct {
	using base_pattern: Pattern,
	name: string,
}
new_ident_pattern :: proc(name: string, base: Node) -> ^Ident_Pattern {
    ident := new(Ident_Pattern)
    ident ^= Ident_Pattern { name=name, base_node=base }
    connect(&ident.base_pattern, ident)
    return ident
}

List_Pattern :: struct {
	using base_pattern: Pattern,
	elements: []Pattern,
}

Tuple_Pattern :: struct {
    using base_pattern: Pattern,
    elements: []Pattern,
}

Record_Pattern :: struct {
    using base_pattern: Pattern,
    fields: []Pattern_Field,
    has_ellipsis: bool,
}
Pattern_Field :: struct {
    using base_node: Node,
    label: string,
    pattern: ^Pattern,
}

Constructed_Pattern :: struct {
    using base_pattern: Pattern,
    constructor: ^Pattern,
    args: []Pattern,
}

Infix_Pattern :: struct {
    using base_pattern: Pattern,
    operator: string,
    left: ^Pattern,
    right: ^Pattern,
}

Typed_Pattern :: struct {
    using base_pattern: Pattern,
    pattern: ^Pattern,
    type: ^Type,
}

Layered_Pattern :: struct {
    using base_pattern: Pattern,
    name: string,
    type: ^Type,
    pattern: ^Pattern,
}