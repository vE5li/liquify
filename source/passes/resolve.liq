#functions {

    resolve {

        compress function(list) {
            set return_list := $[]

            iterate list as key, value {
                set item := pass(value:item)
                set return_list := append(return_list, item)
            }

            return return_list
        }

        compress_flatten function(list) {
            set return_list := $[]

            iterate list as key, value {
                set item := pass(value:item, $!true)
                set return_list := append(return_list, item)
            }

            return return_list
        }

        temporary_variable function(flatten) {
            if ?false(flatten) {
                return $[ #last ]
            }

            set id := &root:scopes:-1:variable_id
            set &root:scopes:-1:variable_id := add(id, $1) @ id + $1

            set variable_name := path($#scope, identifier($_ ~ id))
            set instruction := list($#modify, list($#data, variable_name), $[ #last ])
            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)

            return list(variable_name)
        }

        keyword function(self) {
            return keyword(self:entries:keyword)
        }

        path function(self) {
            set steps := call($resolve:compress, self:entries:steps)
            return invoke($#path, steps)
        }

        list function(self) {
            set items := call($resolve:compress, self:entries:items)
            return invoke($#list, items)
        }

        map function(self) {
            set entries := call($resolve:compress, self:entries:entries)
            return invoke($#map, entries)
        }

        boolean function(self) {
            return self:entries:state == $true
        }

        number function(self) {
            if self:entries:negative {
                return negate(self:entries:value)
            }
            return self:entries:value
        }

        value function(self) {
            return pass(self:entries:value)
        }

        parameter function(self) {
            if self:entries:list {
                return list($#list, self:entries:identifier)
            } else {
                return list($#single, self:entries:identifier)
            }
        }

        immediate function(self, flatten) {
            set immediate := pass(self:entries:immediate)
            return list($#data, immediate)
        }

        absolute_path function(self, flatten) {
            set path := pass(self:entries:path)

            if ?path(path) {
                set path:1 := keyword(path:1)
            } else {
                set path := keyword(path)
            }

            return list(path)
        }

        relative_path function(self, flatten) {
            set path := pass(self:entries:path)
            set path := path($#scope, path)
            return list(path)
        }

        index function(self, flatten) {
            set collection := pass(self:entries:collection, $!true)
            set index := pass(self:entries:index, $!false)
            set instruction := list($#index, collection, index)

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            return call($resolve:temporary_variable, flatten)
        }

        instruction function(self, flatten) {
            set instruction_name := keyword(self:entries:instruction)
            set parameters := call($resolve:compress_flatten, self:entries:parameters)
            set instruction := push(parameters, instruction_name)

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            return call($resolve:temporary_variable, flatten)
        }

        condition function(self, flatten) {
            set condition := keyword(self:entries:condition)
            set condition := list($#data, condition)
            set parameters := call($resolve:compress_flatten, self:entries:parameters)
            set instruction := push(parameters, condition, $#boolean)

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            return call($resolve:temporary_variable, flatten)
        }

        comparison function(self, flatten) {
            set left := pass(self:entries:left, $!true)
            set right := pass(self:entries:right, $!true)
            set comparitor := list($#data, keyword(self:entries:comparitor))
            set instruction := list($#boolean, comparitor, left, right)

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            return call($resolve:temporary_variable, flatten)
        }

        concatinate function(self, flatten) {
            set values := call($resolve:compress_flatten, self:entries:values)
            set instruction := push(values, $#string)

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            return call($resolve:temporary_variable, flatten)
        }

        substitue_value function(self, flatten) {
            return pass(self:entries:value, flatten)
        }

        set function(self) {
            set path := pass(self:entries:path, $!true)
            set source := pass(self:entries:value, $!false)
            set destination := push(path, $#data)
            set instruction := list($#modify, destination, source)
            return instruction
        }

        return function(self) {
            if ?present(self:entries, $value) {
                set value := pass(self:entries:value, $!false)
                return list($#return, value)
            }
            return $[ #return ]
        }

        if function(self) {
            set condition := pass(self:entries:condition, $!false)
            set instruction := list($#if, $[ #data #true ], condition)
            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)

            iterate self:entries:statements as key, statement {
                set statement := pass(statement:item)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, statement)
            }

            if ?present(self:entries, $else) {
                pass(self:entries:else)
            }

            return $[ #end ]
        }

        else function(self) {
            set &root:scopes:-1:bytecode := append(&root:scopes:-1:bytecode, $#else)

            if ?present(self:entries, $condition) {
                set condition := pass(self:entries:condition, $!false)
                set instruction := list($#if, $[ #data #true ], condition)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            }

            iterate self:entries:statements as key, statement {
                set statement := pass(statement:item)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, statement)
            }

            if ?present(self:entries, $else) {
                pass(self:entries:else)
            }

            if ?present(self:entries, $condition) {
                set &root:scopes:-1:bytecode := append(&root:scopes:-1:bytecode, $#end)
            }

            return self
        }

        while function(self) {
            set scope := map($bytecode, $[], $variable_id, &root:scopes:-1:variable_id)
            set &root:scopes := append(&root:scopes, scope)

            set condition_variable := pass(self:entries:condition, $!true)
            set variable_id := &root:scopes:-1:variable_id
            set condition_bytecode := &root:scopes:-1:bytecode

            set &root:scopes := remove(&root:scopes, $-1)
            set &root:scopes:-1:variable_id := variable_id

            set instruction := list($#while, $[ #data #true ], condition_variable)
            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, condition_bytecode)
            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)

            iterate self:entries:statements as key, statement {
                set statement := pass(statement:item)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, statement)
            }

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, condition_bytecode)
            return $[ #end ]
        }

        ensure function(self) {
            set parameters := call($resolve:compress_flatten, self:entries:parameters)
            set instruction := push(parameters, $[ #data #true ], $#ensure)
            return instruction
        }

        call function(self) {
            pass(self:entries:instruction, $!false)
            return $[]
        }

        iterate function(self) {
            set collection := pass(self:entries:collection, $!false)
            set &root:scopes:-1:bytecode := append(&root:scopes:-1:bytecode, $#iterate, collection)

            if ?present(self:entries, $key) {
                set key_path := path($#scope, self:entries:key)
                set value_path := path($#scope, self:entries:value)
                set key_parameter := list($#data, key_path)
                set value_paramter := list($#data, value_path)

                set instruction := list($#modify, key_parameter, $[ #last:key ], value_paramter, $[ #last:value ])
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            }

            iterate self:entries:statements as key, statement {
                set statement := pass(statement:item)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, statement)
            }

            return $[ #end ]
        }

        statement function(self) {
            return pass(self:entries:statement)
        }

        function function(self) {
            set scope := map($bytecode, $[], $variable_id, $0)
            set &root:scopes := append(&root:scopes, scope)

            iterate self:entries:parameters as key, parameter {
                set parameter := pass(parameter:item)
                set &root:scopes:-1:bytecode := append(&root:scopes:-1:bytecode, parameter)
            }

            iterate self:entries:statements as key, statement {
                set statement := pass(statement:item)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, statement)
            }

            set bytecode := &root:scopes:-1:bytecode
            set &root:scopes := remove(&root:scopes, $-1)
            return bytecode
        }

        pass_handler function(self) {
            set pass := pass(self:entries:pass)
            set handlers := call($resolve:compress, self:entries:handlers)
            return map(pass := handlers)
        }

        type function(self) {
            set type_list := list(keyword(self:entries:identifier))

            if ?present(self:entries, $key) {
                set type_list := append(type_list, self:entries:key)
            }

            if ?present(self:entries, $constraints) {
                set constraints := call($resolve:compress, self:entries:constraints)

                if ?list(constraints:1) {
                    set type_list := merge(type_list, constraints)
                } else {
                    set type_list := append(type_list, constraints)
                }
            }

            return type_list
        }

        piece function(self) {
            if ?present(self:entries, $key) {
                set key := pass(self:entries:key)

                if ?present(self:entries, $value) {
                    set value := pass(self:entries:value)
                    return list($#data, key, value)
                }

                set self:entries:type:entries := insert(self:entries:type:entries, $key, key)
            }

            ensure(?not_present(self:entries, $value), $"immediate value must have a key")
            return pass(self:entries:type)
        }

        flavour function(self) {
            set pieces := call($resolve:compress, self:entries:pieces)
            return pieces
        }

        template function(self) {
            ensure(?not_empty(self:entries:flavours), $"template may not be empty")
            set template_body := $[]

            if ?present(self:entries, $pass_handlers) {
                set pass_handlers := call($resolve:compress, self:entries:pass_handlers)
                set pass_handlers := push(pass_handlers, ${})
                set passes_map := invoke($#merge, pass_handlers)
                set template_body := append(template_body, passes_map)
            }

            set flavours := call($resolve:compress, self:entries:flavours)
            set template_body := merge(template_body, flavours)

            return template_body
        }

        property_parameter function(self) {

            if ?present(self:entries, $constant) {
                if self:entries:constant == $none {
                    return $#none
                } else self:entries:constant == $alphabet_upper_case {
                    return $[ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ]
                } else self:entries:constant == $alphabet_lower_case {
                    return $[ a b c d e f g h i j k l m n o p q r s t u v w x y z ]
                } else {
                    error($"invalid constant " ~ self:entries:constant)
                }
            }

            return pass(self:entries:value)
        }

        property function(self, entries) {
            set parameters := $[]

            iterate self:entries:parameters as key, parameter {
                set parameter := pass(parameter:item)
                if ?list(parameter) {
                    set parameters := merge(parameters, parameter)
                } else {
                    set parameters := append(parameters, parameter)
                }
            }

            if self:entries:property == $block_comment {
                set entries:#block_comments := append(entries:#block_comments, parameters)
            } else self:entries:property == $note {
                set entries:#notes := insert(entries:#notes, parameters:1, parameters:2)
            } else self:entries:property == $line_comment {
                set entries:#line_comments := append(entries:#line_comments, parameters:1)
            } else self:entries:property == $delimiter {
                set entries:#delimiters := append(entries:#delimiters, parameters)
            } else self:entries:property == $translate {
                set entries:#translate := insert(entries:#translate, parameters:1, parameters:2)
            } else self:entries:property == $replace {
                set entries:#replace := insert(entries:#replace, parameters:1, parameters:2)
            } else self:entries:property == $prefix {
                set entries:#prefix := merge(entries:#prefix, parameters)
            } else self:entries:property == $type_prefix {
                set entries:#type_prefix := merge(entries:#type_prefix, parameters)
            } else self:entries:property == $ignored {
                set entries:#ignored := merge(entries:#ignored, parameters)
            } else self:entries:property == $invalid {
                set entries:#invalid := merge(entries:#invalid, parameters)
            } else self:entries:property == $system {
                set identifier := parameters:1
                set digits := remove(parameters, $1)
                set entries:#systems := insert(entries:#systems, identifier, digits)
            } else self:entries:property == $float {
                set entries:#floats := merge(entries:#floats, parameters)
            } else self:entries:property == $negative {
                set entries:#negatives := merge(entries:#negatives, parameters)
            } else self:entries:property == $format {
                set identifier := parameters:1
                set prefix := parameters:2
                set suffix := parameters:3

                if ?not_present(entries:#formats, prefix) {
                    set entries:#formats := insert(entries:#formats, prefix, ${})
                }

                if ?present(entries:#formats[prefix], suffix) {
                    error($"duplicate format of " ~ entries:#formats[prefix][suffix])
                }

                set path := path($#scope:entries:#formats, prefix, suffix)
                modify(path, identifier)
            } else {
                error($"invalid property " ~ self:entries:property)
            }

            return entries
        }

        comment_tokenizer function(self) {
            return ${ #notes {} #block_comments [] #line_comments [] }
        }

        number_tokenizer function(self) {
            return ${ #systems {} #formats {} #floats [] #negatives [] }
        }

        character_tokenizer function(self) {
            return ${ #delimiters [] #replace {} }
        }

        string_tokenizer function(self) {
            return ${ #delimiters [] #replace {} }
        }

        operator_tokenizer function(self) {
            return ${ #translate {} #invalid [] #ignored [] }
        }

        keyword_tokenizer function(self) {
            return ${ #translate {} #invalid [] #ignored [] }
        }

        identifier_tokenizer function(self) {
            return ${ #prefix [] #type_prefix [] #invalid [] #ignored [] }
        }

        tokenizer function(self) {
            set tokenizer := pass(self:entries:tokenizer)

            iterate self:entries:tokenizer:entries:properties as key, property {
                set tokenizer := pass(property:item, tokenizer)
            }

            iterate tokenizer as key, value {
                if ?empty(value) {
                    set tokenizer := remove(tokenizer, key)
                }
            }

            return tokenizer
        }

        #top function(self) {
            set &root:scopes := $[]
            set code := $""

            if ?present(self:entries, $values) {
                set values := call($resolve:compress, self:entries:values)
                iterate values as key, value {
                    set code := code ~ serialize(value) ~ $' '
                }
            }

            set &build:code := code
            return self
        }
    }
}
