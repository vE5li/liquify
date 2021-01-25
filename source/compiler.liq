core            [ tokenizer parser ]

dependencies    [ format file color debug position ]

pipeline        [ resolve ]

project {
    name            "liquify"
    author          "ve5li"
    contact         "ve5li@tuta.io"
}

directory {
    core            "/usr/share/liquify/data/core/"
    pass            "/usr/share/liquify/data/passes/"
    utility         "/usr/share/shego/library/"
}

#function {

    #main function([arguments]) {

        set start_time := time()
        set configuration := call(&function:process_arguments, arguments)

        if configuration:help {
            call(&function:show_help)
            terminate
        }

        set compiler := map($debug, configuration:debug, $#pipeline, &root:pipeline)

        iterate &root:core as key, file {
            set core_data := read_map(&root:directory:core ~ file ~ $".data")
            set compiler := merge(compiler, core_data)
        }

        iterate &root:dependencies as key, file {
            set library_data := read_map(&root:directory:utility ~ file ~ $".data")
            set compiler := merge(compiler, library_data)
            set &root := merge(&root, library_data)
        }

        call(&function:debug_log, configuration:debug, $"libraries loaded")
        call(&function:debug_log, configuration:debug, $"loading the pipeline")

        iterate compiler:#pipeline as key, pass {
            call(&function:debug_log, configuration:debug, $"loading pass " ~ pass)
            set pass_data := read_map(&root:directory:pass ~ pass ~ $".data")
            set compiler := merge(compiler, pass_data)
        }

        system($"cp", $"-r", $"-T", configuration:source, configuration:output)
        set result := system($"find", configuration:output, $"-name", $"*.liq")
        set files := split(result:output, $'\n', $!true)

        iterate files as key, input_file {
            call(&function:debug_log, configuration:debug, $"compiling file " ~ &root:#color:magenta ~ input_file ~ &root:#color:none)

            set content := read_file(input_file)
            call(&function:debug_log, configuration:debug, $"tokenizing... ")
            set tokenizer_data := tokenize(compiler, content, input_file, $!false)
            call(&function:debug_log, configuration:debug, $"parsing... ")
            set parser_data := parse(compiler, tokenizer_data:token_stream, tokenizer_data:registry)
            call(&function:debug_log, configuration:debug, $"building... ")
            set build_data := build(compiler, parser_data)

            system($"rm", input_file)
            set output_file := slice(input_file, $1, $-4) ~ $"data"
            write_file(output_file, build_data:code)
        }

        set delta_time := divide(subtract(time(), start_time), $1000.0) @ time() - start_time  / $1000.0
        set formatted := slice(string(delta_time), $1, $3)
        call(&function:#print:success, $"completed in " ~ formatted ~ $"s")
    }

    process_arguments function(arguments) {
        set configuration := ${ help !false files [] debug !false source "source/" output "data/" }
        set count := length(arguments)
        set index := $2

        while index <= count {
            set argument := arguments[index]

            if argument == $"-h" {
                set configuration:help := $!true
            } else argument == $"-s" {
                ensure(count > index, $"expected source directory")
                ensure(#not_present(&scope, $source_set), $"source directory may only be set once")

                set index := add(index, $1) @index + $1
                set configuration:source := arguments[index]
                set source_set := $!true
            } else argument == $"-o" {
                ensure(count > index, $"expected output directory")
                ensure(#not_present(&scope, $output_set), $"output directory may only be set once")

                set index := add(index, $1) @index + $1
                set configuration:output := arguments[index]
                set output_set := $!true
            } else argument == $"-d" {
                ensure(#not_present(&scope, $debug_set), $"debug flag may only be set once")
                set configuration:debug := $!true
                set debug_set := $!true
            } else {
                print_line(string($"invalid flag ", argument)) @($"invalid flag " ~ argument)
                set configuration:help := $!true
                @break
            }

            set index := add(index, $1) @ index + $1
        }

        return configuration
    }

    debug_log function(debug, [arguments]) {
        if debug {
            call_list(&function:#print:debug, arguments)
        }
    }

    show_help function() {
        print_line()
        print_line($"usage:")
        print_line($"  $         liquify [options]")
        print_line()
        print_line($"options:")
        print_line($" -h         show help menu")
        print_line($" -d         turn on debug mode")
        print_line($" -s         set source directory")
        print_line($" -o         set output directory")
        print_line()
        print_line($"contact:")
        print_line($"  #         github.com/ve5li/liquify")
        print_line($"  @         ve5li@tuta.io")
        print_line()
    }
}
