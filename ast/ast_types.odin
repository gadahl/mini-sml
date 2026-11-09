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
new_bad_type :: proc(base: Node) -> ^Bad_Type {
    bad := new(Bad_Type)
    bad ^= { base_node=base }
    connect(&bad.base_type, bad)
    return bad
}

Ident_Type :: struct {
    using base_type: Type,
    name: string,
}
new_ident_type :: proc(name: string, base: Node) -> ^Ident_Type {
    ident := new(Ident_Type)
    ident ^= Ident_Type { name=name, base_node=base }
    connect(&ident.base_type, ident)
    return ident
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