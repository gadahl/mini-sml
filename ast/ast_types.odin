package ast

Type :: struct {
    using base_node: Node, 
	type_variant: Any_Type,
}

Any_Type :: union {
    ^Bad_Type,
    ^Ident_Type,
    ^Constructed_Type,
    ^Record_Type,
    ^Tuple_Type,
    ^Func_Type,
}

connect_type :: proc(base: ^Type, variant: Any_Type) {
    base.type_variant = variant
    connect_node(&base.base_node, base)
}


// Typeessions

Bad_Type :: struct {
	using base_type: Type,
}
make_bad_type :: proc() -> ^Bad_Type {
    bad := new(Bad_Type)
    bad^ = {type_variant = bad, node_variant = &bad.base_type}
    return bad
}

Ident_Type :: struct {
    using base_type: Type,
    name: string,
}

Constructed_Type :: struct {
    using base_type: Type,
    constructor: ^Type,
    args: [dynamic]Type,
}

Record_Type :: struct {
    using base_type: Type,
    fields: [dynamic]Type_Field,
}
Type_Field :: struct {
    using base_node: Node,
    label: string,
    type: ^Type,
}

Tuple_Type :: struct {
    using base_type: Type,
    components: [dynamic]Type,
}

Func_Type :: struct {
    using base_type: Type,
    domain: ^Type,
    codomain: ^Type,
}