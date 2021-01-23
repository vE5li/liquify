#function {

    resolve {

        compress Function(list) {
            set return_list := $[]

            iterate list as key, value {
                set part := pass(value:part)
                set return_list := append(return_list, part)
            }

            return return_list
        }

        compress_flatten Function(list) {
            set return_list := $[]

            iterate list as key, value {
                set part := pass(value:part, $!true)
                set return_list := append(return_list, part)
            }

            return return_list
        }

        temporary_variable Function(flatten) {
            if #false(flatten) {
                return $[ #last ]
            }

            set id := &root:scopes:-1:variable_id
            set &root:scopes:-1:variable_id := add(id, $1) @ id + $1

            set variable_name := path($#scope, identifier($_ ~ id))
            set instruction := list($#modify, list($#data, variable_name), $[ #last ])
            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)

            return list(variable_name)
        }

        keyword Function(self) {
            return keyword(self:keyword)
        }

        path Function(self) {
            set steps := call(&function:resolve:compress, self:steps)
            return invoke($#path, steps)
        }

        list Function(self) {
            set items := call(&function:resolve:compress, self:items)
            return invoke($#list, items)
        }

        map Function(self) {
            set entries := call(&function:resolve:compress, self:entries)
            return invoke($#map, entries)
        }

        boolean Function(self) {
            return self:state == $true
        }

        value Function(self) {
            if #present(self, $negative) { @ #present(self, $negative) && self:negative
                if self:negative {
                    return negate(self:value)
                }
            }

            return pass(self:value)
        }

        parameter Function(self) {
            if self:list {
                return list($#list, self:identifier)
            } else {
                return list($#single, self:identifier)
            }
        }

        immediate Function(self, flatten) {
            set immediate := pass(self:immediate)
            return list($#data, immediate)
        }

        absolute_path Function(self, flatten) {
            set path := pass(self:path)

            if #path(path) {
                set path:1 := keyword(path:1)
            } else {
                set path := keyword(path)
            }

            return list(path)
        }

        relative_path Function(self, flatten) {
            set path := pass(self:path)
            set path := path($#scope, path)
            return list(path)
        }

        index Function(self, flatten) {
            set collection := pass(self:collection, $!true)
            set index := pass(self:index, $!false)
            set instruction := list($#index, collection, index)

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            return call(&function:resolve:temporary_variable, flatten)
        }

        instruction Function(self, flatten) {
            set instruction_name := keyword(self:instruction)
            set parameters := call(&function:resolve:compress_flatten, self:parameters)
            set instruction := push(parameters, instruction_name)

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            return call(&function:resolve:temporary_variable, flatten)
        }

        condition Function(self, flatten) {
            set condition := pass(self:condition)
            set condition := list($#data, condition)
            set parameters := call(&function:resolve:compress_flatten, self:parameters)
            set instruction := push(parameters, condition, $#boolean)

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            return call(&function:resolve:temporary_variable, flatten)
        }

        comparison Function(self, flatten) {
            set left := pass(self:left, $!true)
            set right := pass(self:right, $!true)
            set comparitor := list($#data, keyword(self:comparitor))
            set instruction := list($#boolean, comparitor, left, right)

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            return call(&function:resolve:temporary_variable, flatten)
        }

        concatinate Function(self, flatten) {
            set values := call(&function:resolve:compress_flatten, self:values)
            set instruction := push(values, $#string)

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            return call(&function:resolve:temporary_variable, flatten)
        }

        substitue_value Function(self, flatten) {
            return pass(self:value, flatten)
        }

        set Function(self) {
            set path := pass(self:path, $!true)
            set source := pass(self:value, $!false)
            set destination := push(path, $#data)
            set instruction := list($#modify, destination, source)
            return instruction
        }

        return Function(self) {
            if #present(self, $value) {
                set value := pass(self:value, $!false)
                return list($#return, value)
            }
            return $[ #return ]
        }

        if Function(self) {
            set condition := pass(self:condition, $!false)
            set instruction := list($#if, $[ #data #true ], condition)
            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)

            iterate self:statements as key, statement {
                set statement := pass(statement:part)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, statement)
            }

            if #present(self, $else) {
                pass(self:else)
            }

            return $[ #end ]
        }

        else Function(self) {
            set &root:scopes:-1:bytecode := append(&root:scopes:-1:bytecode, $#else)

            if #present(self, $condition) {
                set condition := pass(self:condition, $!false)
                set instruction := list($#if, $[ #data #true ], condition)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            }

            iterate self:statements as key, statement {
                set statement := pass(statement:part)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, statement)
            }

            if #present(self, $else) {
                pass(self:else)
            }

            if #present(self, $condition) {
                set &root:scopes:-1:bytecode := append(&root:scopes:-1:bytecode, $#end)
            }

            return self
        }

        while Function(self) {
            set scope := map($bytecode, $[], $variable_id, &root:scopes:-1:variable_id)
            set &root:scopes := append(&root:scopes, scope)

            set condition_variable := pass(self:condition, $!true)
            set variable_id := &root:scopes:-1:variable_id
            set condition_bytecode := &root:scopes:-1:bytecode

            set &root:scopes := remove(&root:scopes, $-1)
            set &root:scopes:-1:variable_id := variable_id

            set instruction := list($#while, $[ #data #true ], condition_variable)
            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, condition_bytecode)
            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)

            iterate self:statements as key, statement {
                set statement := pass(statement:part)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, statement)
            }

            set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, condition_bytecode)
            return $[ #end ]
        }

        ensure Function(self) {
            set parameters := call(&function:resolve:compress_flatten, self:parameters)
            set instruction := push(parameters, $[ #data #true ], $#ensure)
            return instruction
        }

        call Function(self) {
            pass(self:instruction, $!false)
            return $[]
        }

        iterate Function(self) {
            set collection := pass(self:collection, $!false)
            set &root:scopes:-1:bytecode := append(&root:scopes:-1:bytecode, $#iterate, collection)

            if #present(self, $key) {
                set key_path := path($#scope, self:key)
                set value_path := path($#scope, self:value)
                set key_parameter := list($#data, key_path)
                set value_paramter := list($#data, value_path)

                set instruction := list($#modify, key_parameter, $[ #last:selector ], value_paramter, $[ #last:instance ])
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, instruction)
            }

            iterate self:statements as key, statement {
                set statement := pass(statement:part)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, statement)
            }

            return $[ #end ]
        }

        statement Function(self) {
            return pass(self:statement)
        }

        function Function(self) {
            set scope := map($bytecode, $[], $variable_id, $0)
            set &root:scopes := append(&root:scopes, scope)

            iterate self:parameters as key, parameter {
                set parameter := pass(parameter:part)
                set &root:scopes:-1:bytecode := append(&root:scopes:-1:bytecode, parameter)
            }

            iterate self:statements as key, statement {
                set statement := pass(statement:part)
                set &root:scopes:-1:bytecode := merge(&root:scopes:-1:bytecode, statement)
            }

            set bytecode := &root:scopes:-1:bytecode
            set &root:scopes := remove(&root:scopes, $-1)
            return bytecode
        }

        #top Function(self) {
            set &root:scopes := $[]
            set code := $""

            if #present(self, $values) {
                set values := call(&function:resolve:compress, self:values)
                iterate values as key, value {
                    set code := code ~ serialize(value) ~ $' '
                }
            }

            set &build:code := code
            return self
        }
    }
}
