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


// Patternessions

Bad_Pattern :: struct {
	using base_pattern: Pattern,
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
    label: string,
    pattern: Pattern,
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