project {
    name            "liquify"
    author          "ve5li"
    contact         "ve5li@tuta.io"
}

directories {
    core            "/usr/share/liquify/data/core/"
    pass            "/usr/share/liquify/data/passes/"
    utility         "/usr/share/shego/data/"
}

extentions {
    liquify         "liq"
    data            "data"
}

command_lookup {
    help            { flag "-h" long "--help"       environment "LIQUIFY_SHOW_HELP"         default !false      once !false }
    debug           { flag "-d" long "--debug"      environment "LIQUIFY_DEBUG"             default !false      once !true  }
    caching         { flag "-c" long "--no-caching" environment "LIQUIFY_ENABLE_CACHING"    default !true       once !true  }
    source          { flag "-s" long "--source"     environment "LIQUIFY_SOURCE_DIRECTORY"  default "source/"   once !true  }
    output          { flag "-o" long "--output"     environment "LIQUIFY_OUTPUT_DIRECTORY"  default "data/"     once !true  }
}

#functions {

    #main function([arguments: string]) {

        set start_time := time()
        set dependencies := $[ format color debug interface ]

        iterate dependencies as key, file {
            set library_data := read_map(&root:directories:utility ~ file ~ $'.' ~ &root:extentions:data)
            set &root := merge(&root, library_data)
        }

        set configuration := call($#interface:process_arguments, &root:command_lookup, arguments)
        set &root:debug := configuration:debug

        if configuration:help {
            call($show_help)
            terminate
        }

        set compiler_core := $[ tokenizer parser ]
        set compiler_pipeline := $[ resolve ]
        set compiler_dependencies := $[ format color debug position ]
        set compiler := map($debug := configuration:debug, $#pipeline := compiler_pipeline)

        iterate compiler_core as key, file {
            set core_data := read_map(&root:directories:core ~ file ~ $'.' ~ &root:extentions:data)
            set compiler := merge(compiler, core_data)
        }

        iterate compiler_dependencies as key, file {
            set library_data := read_map(&root:directories:utility ~ file ~ $'.' ~ &root:extentions:data)
            set compiler := merge(compiler, library_data)
            set &root := merge(&root, library_data)
        }

        call($debug_log, configuration:debug, $"libraries loaded")
        call($debug_log, configuration:debug, $"loading the pipeline")

        iterate compiler:#pipeline as key, pass {
            call($debug_log, configuration:debug, $"loading pass " ~ pass)
            set pass_data := read_map(&root:directories:pass ~ pass ~ $'.' ~ &root:extentions:data)
            set compiler := merge(compiler, pass_data)
        }

        if configuration:caching {
            set cache := call($load_cache, configuration:debug)
        }

        silent($"cp", $"-r", $"-T", configuration:source, configuration:output)
        set result := silent($"find", configuration:output, $"-name", $"*." ~ &root:extentions:liquify) @ fix this to use the source directory
        set files := split(result:output, $'\n', $!true)

        iterate files as key, input_file {
            set output_file := slice(input_file, $1, $-4) ~ &root:extentions:data
            set content := read_file(input_file)

            if configuration:caching {
                if ?present(cache, input_file) {
                    if cache[input_file][$source] == content {
                        silent($"rm", input_file)
                        write_file(output_file, cache[input_file][$compiled])
                        continue()
                    }
                }
            }

            call($#print:color, &root:#color:cyan, $"build", $"compiling file " ~ &root:#color:cyan ~ input_file ~ &root:#color:none)
            call($debug_log, configuration:debug, $"tokenizing... ")
            set tokenizer_data := tokenize(compiler, content, input_file, $!false, $!true)
            call($debug_log, configuration:debug, $"parsing... ")
            set parser_data := parse(compiler, tokenizer_data:token_stream, tokenizer_data:registry)
            call($debug_log, configuration:debug, $"building... ")
            set build_data := build(compiler, parser_data)

            write_file(output_file, build_data:code)
            silent($"rm", input_file)

            if configuration:caching {
                set entry := map($source := content, $compiled := build_data:code)
                set cache := overwrite(cache, input_file, entry)
            }
        }

        if configuration:caching {
            call($save_cache, configuration:debug, cache)
        }

        set delta_time := (time() - start_time) / $1000.0
        set formatted := slice(string(delta_time), $1, $3)
        call($#print:success, $"completed in " ~ formatted ~ $"s")
    }

    load_cache function(debug: boolean) {
        set cache_file := environment($"HOME") ~ $"/.cache/liquify." ~ &root:extentions:data
        call($debug_log, debug, $"loading cache from file " ~ &root:#color:magenta ~ cache_file ~ &root:#color:none)
        silent($"touch", cache_file)
        return read_map(cache_file)
    }

    save_cache function(debug: boolean, cache: map) {
        set cache_file := environment($"HOME") ~ $"/.cache/liquify." ~ &root:extentions:data
        call($debug_log, debug, $"saving cache to file " ~ &root:#color:magenta ~ cache_file ~ &root:#color:none)
        write_map(cache_file, cache)
    }

    debug_log function(debug: boolean, [arguments]) {
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
