#comment_tokenizer comment_tokenizer() {

    block_comment("@@", "@@")
    line_comment('@')

    note("TODO ", todo)
    note("FIX ", fix)
    note("WIP ", wip)
}

#number_tokenizer number_tokenizer() {

    system(binary, '0', '1')
    system(decimal, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
    system(duodecimal, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'X', 'E')
    system(hexadecimal, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F')

    format(decimal, $none, $none)
    format(decimal, "0d", $none)
    format(binary, "0b", $none)
    format(duodecimal, "0z", $none)
    format(hexadecimal, "0x", $none)

    float('.')
}

#character_tokenizer character_tokenizer() {

    delimiter('\'', '\'')

    replace("\\\\", '\\')
    replace("\\\'", '\'')
    replace("\\\"", '\"')
    replace("\\0", '\0')
    replace("\\b", '\b')
    replace("\\n", '\n')
    replace("\\t", '\t')
    replace("\\r", '\r')
    replace("\\e", '\e')
}

#string_tokenizer string_tokenizer() {

    delimiter('\"', '\"')

    replace("\\\\", '\\')
    replace("\\\'", '\'')
    replace("\\\"", '\"')
    replace("\\0", '\0')
    replace("\\b", '\b')
    replace("\\n", '\n')
    replace("\\t", '\t')
    replace("\\r", '\r')
    replace("\\e", '\e')
}

#operator_tokenizer operator_tokenizer() {

    translate(":=", assign)
    translate("&&", logical_and)
    translate("^^", logical_xor)
    translate("||", logical_or)
    translate("==", equals)
    translate("!=", not_equals)
    translate(">=", not_smaller)
    translate("<=", not_bigger)
    translate("<<", shift_left)
    translate(">>", shift_right)
    translate(">", bigger)
    translate("<", smaller)
    translate(':', index)
    translate('[', open_square)
    translate(']', close_square)
    translate('{', open_curly)
    translate('}', close_curly)
    translate('(', open_round)
    translate(')', close_round)
    translate('!', boolean)
    translate('$', immediate)
    translate('+', add)
    translate('-', subtract)
    translate('*', multiply)
    translate('/', divide)
    translate('%', modulo)
    translate('~', concatinate)
    translate('&', and)
    translate('^', xor)
    translate('|', or)
    translate(',', comma)
    translate('#', keyword)

    ignored('\r', '\t', '\n', ' ')
    invalid('\\', ';')
}

#identifier_tokenizer identifier_tokenizer() {

    prefix($alphabet_lower_case)
    prefix($alphabet_upper_case)
    prefix(_)
}
