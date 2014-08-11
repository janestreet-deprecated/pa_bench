open Camlp4.PreCast

let libname () = Pa_ounit.libname ()

let drop_benches = ref false
let () =
  Camlp4.Options.add "-pa-bench-drop" (Arg.Set drop_benches) "Drop inline benchmarks"

let descr _loc =
  let filename = Loc.file_name  _loc in
  let line     = Loc.start_line _loc in
  let start_pos = Loc.start_off _loc - Loc.start_bol _loc in
  let end_pos   = Loc.stop_off  _loc - Loc.start_bol _loc in
  <:expr< $str:filename$ >>,
  <:expr< $`int:line$ >>,
  <:expr< $`int:start_pos$ >>,
  <:expr< $`int:end_pos$ >>

let apply_to_descr_bench lid _loc e_opt name more_arg =
  if !drop_benches then
    <:str_item< >>
  else begin
    Pa_type_conv.set_conv_path_if_not_set _loc;
    let filename, line, start_pos, end_pos = descr _loc in
    let descr = match e_opt with
      | None -> <:expr< "" >>
      | Some e -> <:expr< $str:Pa_ounit.string_of_expr e$ >>
    in
    let name = <:expr< $str:name$ >> in
    let type_conv_path = <:expr< $str:Pa_type_conv.get_conv_path ()$ >> in
    <:str_item<
      value () =
        if Pa_bench_lib.Benchmark_accumulator.add_benchmarks_flag
        then Pa_bench_lib.Benchmark_accumulator.$lid:lid$ ~name:$name$
          ~code:$descr$ ~type_conv_path:$type_conv_path$
          ~filename:$filename$ ~line:$line$ ~startpos:$start_pos$ ~endpos:$end_pos$
          $more_arg$
        else
          ()
    >>
  end

EXTEND Gram
  GLOBAL: Syntax.str_item;
  Syntax.str_item:
    [[
      "BENCH"; name = Syntax.a_STRING; "=" ; e = Syntax.expr ->
      (* The ignore below allows us to write tests very succinctly. The type checker still
         complains when exp has an arrow type and this prevents errors caused by partial
         application. *)
      apply_to_descr_bench "add_bench" _loc (Some e) name
        <:expr< Pa_bench_lib.Benchmark_accumulator.Entry.Regular_thunk
               (fun () () -> Pervasives.ignore $e$) >>
    | "BENCH_FUN"; name = Syntax.a_STRING; "=" ; e = Syntax.expr ->
      apply_to_descr_bench "add_bench" _loc (Some e) name
        <:expr< Pa_bench_lib.Benchmark_accumulator.Entry.Regular_thunk (fun () -> $e$) >>
    | "BENCH_INDEXED"; name = Syntax.a_STRING;
                       var_name = Syntax.a_LIDENT;
      (* precedence level '^' is slightly higher than '=', i.e. it is higher than '=' but
         lower than everything else. Hence 'args' will parse an expression up to the first
         '='. *)
                       args = Syntax.expr LEVEL "^";
                       "=";
                       e = Syntax.expr ->
      apply_to_descr_bench "add_bench" _loc (Some e) name
        <:expr<
          Pa_bench_lib.Benchmark_accumulator.Entry.Indexed_thunk {
            Pa_bench_lib.Benchmark_accumulator.Entry.arg_name = $str:var_name$;
            Pa_bench_lib.Benchmark_accumulator.Entry.arg_values = $args$;
            Pa_bench_lib.Benchmark_accumulator.Entry.thunk = fun $lid:var_name$ -> $e$ }
        >>
    | "BENCH_MODULE"; name = Syntax.a_STRING; "=" ; expr = Syntax.module_expr ->
      apply_to_descr_bench "add_bench_module" _loc None name
        <:expr< (fun () -> let module M = $expr$ in () ) >>
    ]];
END

let () =
  let current_str_parser, _ = Camlp4.Register.current_parser () in
  Camlp4.Register.register_str_item_parser (fun ?directive_handler _loc stream ->
    let ml = current_str_parser ?directive_handler _loc stream in
    if !drop_benches then
      ml
    else
      <:str_item<
        value () = Pa_bench_lib.Benchmark_accumulator.Current_libname.set $str:libname ()$;
        $ml$;
        value () = Pa_bench_lib.Benchmark_accumulator.Current_libname.unset ();
      >>
  )
