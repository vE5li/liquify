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

#functions {

    #main function([arguments]) {

        set start_time := time()
        set configuration := call($process_arguments, arguments)

        if configuration:help {
            call($show_help)
            terminate
        }

        set compiler := map($debug := configuration:debug, $#pipeline := &root:pipeline)

        iterate &root:core as key, file {
            set core_data := read_map(&root:directory:core ~ file ~ $".data")
            set compiler := merge(compiler, core_data)
        }

        iterate &root:dependencies as key, file {
            set library_data := read_map(&root:directory:utility ~ file ~ $".data")
            set compiler := merge(compiler, library_data)
            set &root := merge(&root, library_data)
        }

        call($debug_log, configuration:debug, $"libraries loaded")
        call($debug_log, configuration:debug, $"loading the pipeline")

        iterate compiler:#pipeline as key, pass {
            call($debug_log, configuration:debug, $"loading pass " ~ pass)
            set pass_data := read_map(&root:directory:pass ~ pass ~ $".data")
            set compiler := merge(compiler, pass_data)
        }

        if configuration:caching {
            set cache := call($load_cache, configuration:debug)
        }

        system($"cp", $"-r", $"-T", configuration:source, configuration:output)
        set result := system($"find", configuration:output, $"-name", $"*.liq") @ fix this to use the source directory
        set files := split(result:output, $'\n', $!true)

        iterate files as key, input_file {
            set output_file := slice(input_file, $1, $-4) ~ $"data"
            set content := read_file(input_file)

            if configuration:caching { @ configuration:caching && ?present(cache, content)
                if ?present(cache, content) {
                    system($"rm", input_file)
                    write_file(output_file, cache[content])
                    continue()
                }
            }

            call($#print:color, &root:#color:cyan, $"build", $"compiling file " ~ input_file)
            call($debug_log, configuration:debug, $"tokenizing... ")
            set tokenizer_data := tokenize(compiler, content, input_file, $!false)
            call($debug_log, configuration:debug, $"parsing... ")
            set parser_data := parse(compiler, tokenizer_data:token_stream, tokenizer_data:registry)
            call($debug_log, configuration:debug, $"building... ")
            set build_data := build(compiler, parser_data)

            write_file(output_file, build_data:code)
            system($"rm", input_file)

            if configuration:caching {
                set cache := overwrite(cache, content, build_data:code)
            }
        }

        if configuration:caching {
            call($save_cache, configuration:debug, cache)
        }

        set delta_time := divide(subtract(time(), start_time), $1000.0) @ time() - start_time  / $1000.0
        set formatted := slice(string(delta_time), $1, $3)
        call($#print:success, $"completed in " ~ formatted ~ $"s")
    }

    load_cache function(debug) {
        set cache_file := environment($"HOME") ~ $"/.cache/liquify"
        call($debug_log, debug, $"loading cache from file " ~ &root:#color:magenta ~ cache_file ~ &root:#color:none)
        system($"touch", cache_file)
        return read_map(cache_file)
    }

    save_cache function(debug, cache) {
        set cache_file := environment($"HOME") ~ $"/.cache/liquify"
        call($debug_log, debug, $"saving cache to file " ~ &root:#color:magenta ~ cache_file ~ &root:#color:none)
        write_map(cache_file, cache)
    }

    process_arguments function(arguments) {
        set configuration := ${ help !false caching !true files [] debug !false source "source/" output "data/" }
        set count := length(arguments)
        set index := $1

        while index <= count {
            set argument := arguments[index]

            if argument == $"-h" {
                set configuration:help := $!true
            } else argument == $"-s" {
                ensure(count > index, $"expected source directory")
                ensure(?not_present(&scope, $source_set), $"source directory may only be set once")

                set index := add(index, $1) @index + $1
                set configuration:source := arguments[index]
                set source_set := $!true
            } else argument == $"-o" {
                ensure(count > index, $"expected output directory")
                ensure(?not_present(&scope, $output_set), $"output directory may only be set once")

                set index := add(index, $1) @index + $1
                set configuration:output := arguments[index]
                set output_set := $!true
            } else argument == $"-c" {
                ensure(?not_present(&scope, $caching_set), $"disable caching flag may only be set once")
                set configuration:caching := $!false
                set caching_set := $!true
            } else argument == $"-d" {
                ensure(?not_present(&scope, $debug_set), $"debug flag may only be set once")
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
            call_list($#print:debug, arguments)
        }
    }

    show_help function() {
        print_line()
        print_line($"usage:")
        print_line($"  $         liquify [options]")
        print_line()
        print_line($"options:")
        print_line($" -h         show help menu")
        print_line($" -c         disable caching")
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
