package ast


Decl :: struct {
    using base_node: Node, // this is `base` or `super` in OOP
	decl_variant: Any_Decl,
}

Any_Decl :: union {
    ^Bad_Decl,
    ^Val_Decl,
    ^Fun_Decl,
    ^Local_Decl,
    ^Infix_Decl,
    ^Empty_Decl,
}


// Declessions

Bad_Decl :: struct {
	using base_decl: Decl,
}

Val_Decl :: struct {
    using base_decl: Decl,
    lhs: ^Pattern,
    rhs: ^Expr,
}

Fun_Decl :: struct {
    using base_decl: Decl,
    arms: []Fun_Arm,
    rhs: ^Expr,
}
Fun_Arm :: struct{
    name: string,
    args: []Pattern,
    expr: ^Expr,
}

Local_Decl :: struct {
    using base_decl: Decl,
    locals: []Decl,
    globals: []Decl,
}

Infix_Decl :: struct {
    using base_decl: Decl,
    snugness: int,
    names: []string,
}

Empty_Decl :: struct {
    using base_decl: Decl,
}
