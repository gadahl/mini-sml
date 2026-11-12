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
    ^Seq_Decl,
}

connect_decl :: proc(base: ^Decl, variant: Any_Decl) {
    base.decl_variant = variant
    connect_node(&base.base_node, base)
}


// Declessions

Bad_Decl :: struct {
	using base_decl: Decl,
}
new_bad_decl :: proc(base: Node) -> ^Bad_Decl {
    bad_decl := new(Bad_Decl)
    bad_decl ^= Bad_Decl { base_node=base }
    connect(&bad_decl.base_decl, bad_decl)
    return bad_decl
}

Val_Decl :: struct {
    using base_decl: Decl,
    is_rec: bool,
    lhs: ^Pattern,
    rhs: ^Expr,
}
new_val_decl :: proc(is_rec: bool, lhs: ^Pattern, rhs: ^Expr, base: Node) -> ^Val_Decl {
    val_decl := new(Val_Decl)
    val_decl ^= Val_Decl { is_rec=is_rec, lhs=lhs, rhs=rhs, base_node=base }
    connect(&val_decl.base_decl, val_decl)
    return val_decl
}

Fun_Decl :: struct {
    using base_decl: Decl,
    arms: [dynamic]^Fun_Arm,
}
new_fun_decl :: proc(arms: [dynamic]^Fun_Arm, base: Node) -> ^Fun_Decl {
    fun_decl := new(Fun_Decl)
    fun_decl ^= Fun_Decl { arms=arms, base_node=base }
    connect(&fun_decl.base_decl, fun_decl)
    return fun_decl
}
Fun_Arm :: struct{
    name: string,
    args: [dynamic]^Pattern,
    expr: ^Expr,
}

Local_Decl :: struct {
    using base_decl: Decl,
    locals: ^Decl,
    globals: ^Decl,
}
new_local_decl :: proc(locals: ^Decl, globals: ^Decl, base: Node) -> ^Local_Decl {
    local_decl := new(Local_Decl)
    local_decl ^= Local_Decl { locals=locals, globals=globals, base_node=base }
    connect(&local_decl.base_decl, local_decl)
    return local_decl
}

Infix_Decl :: struct {
    using base_decl: Decl,
    is_right_assoc: bool,
    snugness: int,
    names: [dynamic]string,
}
new_infix_decl :: proc(is_right_assoc: bool, snugness: int, names: [dynamic]string, base: Node) -> ^Infix_Decl {
    infix_decl := new(Infix_Decl)
    infix_decl ^= Infix_Decl { is_right_assoc=is_right_assoc, snugness=snugness, names=names, base_node=base }
    connect(&infix_decl.base_decl, infix_decl)
    return infix_decl
}

Empty_Decl :: struct {
    using base_decl: Decl,
}
new_empty_decl :: proc(base: Node) -> ^Empty_Decl {
    empty_decl := new(Empty_Decl)
    empty_decl ^= Empty_Decl { base_node=base }
    connect(&empty_decl.base_decl, empty_decl)
    return empty_decl
}

Seq_Decl :: struct {
    using base_decl: Decl,
    decls: [dynamic]^Decl,
}
new_seq_decl :: proc(decls: [dynamic]^Decl, base: Node) -> ^Seq_Decl {
    seq_decl := new(Seq_Decl)
    seq_decl ^= Seq_Decl { decls=decls, base_node=base }
    connect(&seq_decl.base_decl, seq_decl)
    return seq_decl
}
