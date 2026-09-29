package compiler


whitespace_chars :: " \t\r\f\v\n"

symbolic_chars :: "!@#$%^&*`~-+=/|\\?<>:"

reserved_chars :: "()[]{},;"


alpha_keywords :: []string{ 
    "abstype", "and", "andalso", "as", "case", "do", "datatype", 
    "else", "end", "exception", "fn", "fun", "handle", "if", "in", "infix", "infixr", 
    "let", "local", "nonfix", "of", "op", "open", "orelse", 
    "raise", "rec", "then", "type", "val", "with", "withtype", "while",
}

symbolic_keywords :: []string{ 
   ":", "|", "=", "=>", "->", "#",
}