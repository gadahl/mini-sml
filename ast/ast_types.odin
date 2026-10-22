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


Bad_Type :: struct {
	using base_type: Type,
}

Ident_Type :: struct {
    using base_type: Type,
    name: string,
}

Constructed_Type :: struct {
    using base_type: Type,
    constructor: ^Type,
    args: []Type,
}

Record_Type :: struct {
    using base_type: Type,
    fields: []Type_Field,
}
Type_Field :: struct {
    label: string,
    type: Type,
}

Tuple_Type :: struct {
    using base_type: Type,
    components: []Type,
}

Func_Type :: struct {
    using base_type: Type,
    domain: ^Type,
    codomain: ^Type,
}