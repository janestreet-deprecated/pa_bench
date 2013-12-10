open Core.Std
(* This shows some sample uses of BENCH.  Have a look at pa_bench_sample.ml.pp to see how
   the preprocessor works.

   Also see:
   http://docs/programming/performance/inline-benchmarks.html
*)

(* One can specify a benchmark using the following syntax:

     BENCH "name" = expr

   In the above, the value of [expr] is ignored.  This creates a benchmark for [expr],
   that is run using the [inline_benchmarks_runner] script from the command-line. This
   workflow is similar to that of inline unit tests.
*)

BENCH "add mutable" =
  let i = ref 0 in
  for j = 1 to 10_000 do
    i := !i + j
  done;
  !i

BENCH "add functional" =
  let rec f acc j =
    if j > 10_000
    then acc
    else f (acc + j) (j + 1)
  in
  f 0 1

(* One can specify benchmarks that require some initialization using [BENCH_FUN]. For
   example:

      BENCH_FUN "name" =
        let t = create () in
        (fun () -> test_something t)

   The function returned on the RHS of [BENCH_FUN] should have type [unit
   -> unit].

   The reason that the RHS of [BENCH] can be any non-arrow type, while [BENCH_FUN] and
   [BENCH_INDEXED] have constrained types is that BENCH is a special case for writing
   terse macros, while in the other cases the macros cannot be as terse and consequently
   it is less useful to insert an ignore there.
*)

BENCH_FUN "fold list" =
  let l = List.init 10_000 ~f:(fun i -> i) in
  (fun () -> List.fold l ~init:0 ~f:( + ) |> ignore)

(* One can specify benchmarks that have a variable parameter using [BENCH_INDEXED]. This
   allows setup just like [BENCH_FUN].  Note that the parameter given is bound in the RHS
   of [BENCH_INDEXED].

   Indexed tests can be useful in highlighting non-linearities in the execution time of
   functions.
*)

BENCH_INDEXED "fold list indexed" len [1;10;100;1000] =
  let l = List.init len ~f:(fun i -> i) in
  (fun () -> List.fold l ~init:0 ~f:( + ) |> ignore)

(* We can group benchmarks together into modules and the output of
   [inline_benchmarks_runner] will reflect this grouping.

     BENCH_MODULE "Blit tests" = struct

       ..some benchmarks..

     end

  For examples of all of the above see [core_gc.ml] and [core_array.ml].

   Only the generated [inline_benchmarks_runner.exe] depends on [Core_bench] and other
   libraries. The library that includes the the benchmarks itself does not have a
   dependency on [Core_bench]. Doing this is important so that we can add benchmarks to
   [Core] and still avoid cyclic dependencies. Finally, it is important to note that adding
   inline benchmarks should have little effect on the execution or module initialization
   time.
*)

BENCH_MODULE "trivial module" = struct
  BENCH "trivial" = 3
end
