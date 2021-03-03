#templates {

    selector template(resolve[resolve:selector]) {
        [ selector := template(integer) ]
        [ selector := template(boolean) ]
        [ selector := template(keyword) ]
        [ selector := string() ]
        [ selector := character() ]
        [ selector := identifier() ]
    }

    keyword template(resolve[resolve:keyword]) {
        [ operator(keyword) | keyword := identifier() ]
    }

    path template(resolve[resolve:path]) {
        [ steps := confirmed(template(selector), operator(index)) ]
    }

    list template(resolve[resolve:list]) {
        [ operator(open_square) | items := list(template(value)) | operator(close_square) ]
        [ operator(open_square) | items := $[] | operator(close_square) ]
    }

    map template(resolve[resolve:map]) {
        [ operator(open_curly) | entries := list(template(value)) | operator(close_curly) ]
        [ operator(open_curly) | entries := $[] | operator(close_curly) ]
    }

    boolean template(resolve[resolve:boolean]) {
        [ operator(boolean) | state := identifier(true, false) ]
    }

    integer template(resolve[resolve:number]) {
        [ negative := $!true | operator(subtract) | value := integer() ]
        [ negative := $!false | value := integer() ]
    }

    float template(resolve[resolve:number]) {
        [ negative := $!true | operator(subtract) | value := float() ]
        [ negative := $!false | value := float() ]
    }

    value template(resolve[resolve:value]) {
        [ value := template(map) ]
        [ value := template(path) ]
        [ value := template(list) ]
        [ value := identifier() ]
        [ value := template(keyword) ]
        [ value := string() ]
        [ value := character() ]
        [ value := template(integer) ]
        [ value := template(float) ]
        [ value := template(boolean) ]
        [ value := template(tokenizer) ]
        [ value := template(template) ]
        [ value := template(function) ]
    }

    parameter_type template(resolve[resolve:parameter_type]) {
        [ operator(index) | constraints := list(identifier(), operator(multiply)) ]
        [ ]
    }

    parameter template(resolve[resolve:parameter]) {
        [ list := $!true | operator(open_square) | identifier := identifier() | merge(parameter_type) | operator(close_square) ]
        [ list := $!false | identifier := identifier() | merge(parameter_type) ]
    }

    parameter_list template() {
        [ operator(open_round) | parameters := list(template(parameter), operator(comma, assign)) | operator(close_round) ]
        [ operator(open_round) | parameters := $[] | operator(close_round) ]
    }

    immediate template(resolve[resolve:immediate]) {
        [ operator(immediate) | immediate := template(value) ]
    }

    absolute_path template(resolve[resolve:absolute_path]) {
        [ operator(and) | path := template(path) ]
        [ operator(and) | path := template(selector) ]
    }

    relative_path template(resolve[resolve:relative_path]) {
        [ path := template(path) ]
        [ path := template(selector) ]
    }

    index template(resolve[resolve:index]) {
        [ collection := template(substitue_value) | operator(open_square) | index := template(substitue_value) | operator(close_square) ]
    }

    instruction template(resolve[resolve:instruction]) {
        [ instruction := identifier() | operator(open_round) | parameters := list(template(substitue_value), operator(comma, assign)) | operator(close_round) ]
        [ instruction := identifier() | operator(open_round) | parameters := $[] | operator(close_round) ]
    }

    condition template(resolve[resolve:condition]) {
        [ operator(condition) | condition := identifier() | operator(open_round) | parameters := list(template(substitue_value), operator(comma)) | operator(close_round) ]
        [ operator(condition) | condition := identifier() | operator(open_round) | parameters := $[] | operator(close_round) ]
    }

    arithmatic_operator template() {
        [ operator := operator(shift_left) ]
        [ operator := operator(shift_right) ]
        [ operator := operator(add) ]
        [ operator := operator(subtract) ]
        [ operator := operator(multiply) ]
        [ operator := operator(divide) ]
        [ operator := operator(modulo) ]
        [ operator := operator(and) ]
        [ operator := operator(xor) ]
        [ operator := operator(or) ]
    }

    arithmatic_equasion template(resolve[resolve:arithmatic_equasion]) {
        [ terms := confirmed(template(substitue_value), template(arithmatic_operator)) ]
    }

    logical_operator template() {
        [ operator := operator(equals) ]
        [ operator := operator(not_equals) ]
        [ operator := operator(smaller) ]
        [ operator := operator(not_smaller) ]
        [ operator := operator(bigger) ]
        [ operator := operator(not_bigger) ]
        [ operator := operator(logical_and) ]
        [ operator := operator(logical_or) ]
        [ operator := operator(logical_xor) ]
    }

    logical_equasion template(resolve[resolve:logical_equasion]) {
        [ terms := confirmed(template(substitue_value), template(logical_operator)) ]
    }

    concatinate template(resolve[resolve:concatinate]) {
        [ values := confirmed(template(substitue_value), operator(concatinate)) ]
    }

    substitue_value template(resolve[resolve:substitue_value]) {
        [ operator(open_round) | value := template(substitue_value) | operator(close_round) ]
        [ fixed_value := template(immediate) ]
        [ fixed_value := template(absolute_path) ]
        [ fixed_value := template(relative_path) ]
        [ value := template(index) ]
        [ value := template(instruction) ]
        [ value := template(condition) ]
        [ value := template(logical_equasion) ]
        [ value := template(arithmatic_equasion) ]
        [ value := template(concatinate) ]
    }

    @ TODO: not substitue_value in the front
    set template(resolve[resolve:set]) {
        [ identifier(set) | path := template(absolute_path) | operator(assign) | value := template(substitue_value) ]
        [ identifier(set) | path := template(relative_path) | operator(assign) | value := template(substitue_value) ]
        [ identifier(set) | path := template(selector) | operator(assign) | value := template(substitue_value) ]
    }

    return template(resolve[resolve:return]) {
        [ identifier(return) | value := template(substitue_value) ]
        [ identifier(terminate) ]
    }

    break template(resolve[resolve:break]) {
        [ identifier(break) ]
    }

    continue template(resolve[resolve:continue]) {
        [ identifier(continue) ]
    }

    if template(resolve[resolve:if]) {
        [ identifier(if) | condition := template(substitue_value) | merge(scope) | else := template(else) ]
        [ identifier(if) | condition := template(substitue_value) | merge(scope) ]
    }

    else template(resolve[resolve:else]) {
        [ identifier(else) | condition := template(substitue_value) | merge(scope) | else := template(else) ]
        [ identifier(else) | condition := template(substitue_value) | merge(scope) ]
        [ identifier(else) | merge(scope) ]
    }

    while template(resolve[resolve:while]) {
        [ identifier(while) | condition := template(substitue_value) | merge(scope) ]
    }

    ensure template(resolve[resolve:ensure]) {
        [ identifier(ensure) | operator(open_round) | parameters := list(template(substitue_value), operator(comma)) | operator(close_round) ]
    }

    call template(resolve[resolve:call]) {
        [ instruction := template(instruction) ]
    }

    iterate template(resolve[resolve:iterate]) {
        [ identifier(iterate) | collection := template(substitue_value) | identifier(as) | key := identifier() | operator(comma) | value := identifier() | merge(scope) ]
        [ identifier(iterate) | collection := template(substitue_value) | merge(scope) ]
    }

    statement template(resolve[resolve:statement]) {
        [ statement := template(set) ]
        [ statement := template(return) ]
        [ statement := template(break) ]
        [ statement := template(continue) ]
        [ statement := template(if) ]
        [ statement := template(while) ]
        [ statement := template(ensure) ]
        [ statement := template(call) ]
        [ statement := template(iterate) ]
    }

    scope template() {
        [ operator(open_curly) | statements := list(template(statement)) | operator(close_curly) ]
        [ operator(open_curly) | statements := $[] | operator(close_curly) ]
    }

    function template(resolve[resolve:function]) {
        [ identifier(function) | merge(parameter_list) | merge(scope) ]
    }

    pass_handler template(resolve[resolve:pass_handler]) {
        [ pass := identifier() | operator(open_square) | handlers := list(template(value), operator(comma)) | operator(close_square) ]
    }

    pass_handler_list template() {
        [ operator(open_round) | pass_handlers := list(template(pass_handler), operator(comma)) | operator(close_round) ]
        [ operator(open_round) | operator(close_round) ]
    }

    @ TODO: parse individually
    type template(resolve[resolve:type]) {
        [ identifier := identifier() | operator(open_round) | constraints := list(template(value, type), operator(comma)) | operator(close_round) ]
        [ identifier := identifier() | operator(open_round) | operator(close_round) ]
    }

    piece template(resolve[resolve:piece]) {
        [ key := template(value) | operator(assign) | operator(immediate) | value := template(value) ]
        [ key := template(value) | operator(assign) | type := template(type) ]
        [ operator(immediate) | value := template(value) ]
        [ type := template(type) ]
    }

    flavour template(resolve[resolve:flavour]) {
        [ operator(open_square) | pieces := list(template(piece), operator(or)) | operator(close_square) ]
        [ operator(open_square) | pieces := $[] | operator(close_square) ]
    }

    flavour_list template() {
        [ operator(open_curly) | flavours := list(template(flavour)) | operator(close_curly) ]
        [ operator(open_curly) | flavours := $[] | operator(close_curly) ]
    }

    template template(resolve[resolve:template]) {
        [ identifier(template) | merge(pass_handler_list) | merge(flavour_list) ]
    }

    property_parameter template(resolve[resolve:property_parameter]) {
        [ operator(immediate) | constant := identifier() ]
        [ value := template(value) ]
    }

    property template(resolve[resolve:property]) {
        [ property := identifier() | operator(open_round) | parameters := list(template(property_parameter), operator(comma)) | operator(close_round) ]
        [ property := identifier() | operator(open_round) | parameters := $[] | operator(close_round) ]
    }

    property_list template() {
        [ operator(open_curly) | properties := list(template(property)) | operator(close_curly) ]
        [ operator(open_curly) | properties := $[] | operator(close_curly) ]
    }

    comment_tokenizer template(resolve[resolve:comment_tokenizer]) {
        [ identifier(comment_tokenizer) | operator(open_round) | operator(close_round) | merge(property_list) ]
    }

    number_tokenizer template(resolve[resolve:number_tokenizer]) {
        [ identifier(number_tokenizer) | operator(open_round) | operator(close_round) | merge(property_list) ]
    }

    character_tokenizer template(resolve[resolve:character_tokenizer]) {
        [ identifier(character_tokenizer) | operator(open_round) | operator(close_round) | merge(property_list) ]
    }

    string_tokenizer template(resolve[resolve:string_tokenizer]) {
        [ identifier(string_tokenizer) | operator(open_round) | operator(close_round) | merge(property_list) ]
    }

    operator_tokenizer template(resolve[resolve:operator_tokenizer]) {
        [ identifier(operator_tokenizer) | operator(open_round) | operator(close_round) | merge(property_list) ]
    }

    keyword_tokenizer template(resolve[resolve:keyword_tokenizer]) {
        [ identifier(keyword_tokenizer) | operator(open_round) | operator(close_round) | merge(property_list) ]
    }

    identifier_tokenizer template(resolve[resolve:identifier_tokenizer]) {
        [ identifier(identifier_tokenizer) | operator(open_round) | operator(close_round) | merge(property_list) ]
    }

    tokenizer template(resolve[resolve:tokenizer]) {
        [ tokenizer := template(comment_tokenizer) ]
        [ tokenizer := template(number_tokenizer) ]
        [ tokenizer := template(character_tokenizer) ]
        [ tokenizer := template(string_tokenizer) ]
        [ tokenizer := template(operator_tokenizer) ]
        [ tokenizer := template(keyword_tokenizer) ]
        [ tokenizer := template(identifier_tokenizer) ]
    }

    #top template(resolve[resolve:#top]) {
        [ values := list(template(value)) ]
        [ ]
    }
}
