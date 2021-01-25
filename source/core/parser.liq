#template {

    keyword template(resolve[resolve:keyword]) {
        [ operator(keyword) | keyword := identifier() ]
    }

    path template(resolve[resolve:path]) {
        [ steps := confirmed(template(value), operator(index)) ]
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
        [ value := template(function) ]
        [ value := template(template) ]
    }

    parameter template(resolve[resolve:parameter]) {
        [ list := $!true | operator(open_square) | identifier := identifier() | operator(close_square) ]
        [ list := $!false | identifier := identifier() ]
    }

    parameter_list template() {
        [ operator(open_round) | parameters := list(template(parameter), operator(comma)) | operator(close_round) ]
        [ operator(open_round) | parameters := $[] | operator(close_round) ]
    }

    immediate template(resolve[resolve:immediate]) {
        [ operator(immediate) | immediate := template(value) ]
    }

    absolute_path template(resolve[resolve:absolute_path]) {
        [ operator(and) | path := template(value) ]
    }

    relative_path template(resolve[resolve:relative_path]) {
        [ path := template(value) ]
    }

    index template(resolve[resolve:index]) {
        [ collection := template(substitue_value) | operator(open_square) | index := template(substitue_value) | operator(close_square) ]
    }

    instruction template(resolve[resolve:instruction]) {
        [ instruction := identifier() | operator(open_round) | parameters := list(template(substitue_value), operator(comma)) | operator(close_round) ]
        [ instruction := identifier() | operator(open_round) | parameters := $[] | operator(close_round) ]
    }

    condition template(resolve[resolve:condition]) {
        [ condition := template(keyword) | operator(open_round) | parameters := list(template(substitue_value), operator(comma)) | operator(close_round) ]
        [ condition := template(keyword) | operator(open_round) | parameters := $[] | operator(close_round) ]
    }

    comparitor template() {
        [ comparitor := operator(equals) ]
        [ comparitor := operator(not_equals) ]
        [ comparitor := operator(smaller) ]
        [ comparitor := operator(not_smaller) ]
        [ comparitor := operator(bigger) ]
        [ comparitor := operator(not_bigger) ]
    }

    comparison template(resolve[resolve:comparison]) {
        [ left := template(substitue_value) | merge(comparitor) | right := template(substitue_value) ]
    }

    logical_operator template() {
        [ operator := operator(logical_and) ]
        [ operator := operator(logical_or) ]
        [ operator := operator(logical_xor) ]
    }

    logical_equasion template(resolve[resolve:logical_equasion]) {
        [ values := confirmed(template(substitue_value), template(logical_operator)) ]
    }

    concatinate template(resolve[resolve:concatinate]) {
        [ values := confirmed(template(substitue_value), operator(concatinate)) ]
    }

    substitue_value template(resolve[resolve:substitue_value]) {
        [ value := template(immediate) ]
        [ value := template(absolute_path) ]
        [ value := template(relative_path) ]
        [ value := template(index) ]
        [ value := template(instruction) ]
        [ value := template(condition) ]
        [ value := template(comparison) ]
        [ value := template(logical_equasion) ]
        [ value := template(concatinate) ]
        [ operator(open_round) | value := template(substitue_value) | operator(close_round) ]
    }

    @ TODO: not substitue_value in the front
    set template(resolve[resolve:set]) {
        [ identifier(set) | path := template(substitue_value) | operator(assign) | value := template(substitue_value) ]
    }

    return template(resolve[resolve:return]) {
        [ identifier(return) | value := template(substitue_value) ]
        [ identifier(terminate) ]
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

    #top template(resolve[resolve:#top]) {
        [ values := list(template(value)) ]
        [ ]
    }
}
