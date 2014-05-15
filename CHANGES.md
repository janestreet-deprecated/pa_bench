## 109.55.00

- Added support for inline benchmarks using the `BENCH` syntax, similar
  to `TEST`.

    This feature allows users to specify inline benchmarks in any library.

    One can specify a benchmark using the following syntax:

    ```ocaml
    BENCH "name" = expr
    ```

    In the above, the value of `expr` is ignored.  This creates
    a benchmark for `expr`, that is run using the
    `inline_benchmarks_runner` script from the command-line.  This
    workflow is similar to that of inline unit tests.

    One can specify benchmarks that require some initialization using
    `BENCH_FUN`. For example:

    ```ocaml
    BENCH_FUN "name" =
      let t = create () in
      (fun () -> test_something t)
    ```

    The function returned on the RHS of `BENCH_FUN` should have type `unit
    -> unit`. One can specify benchmarks that have a variable parameter
    using `BENCH_INDEXED`. For example:

    ```ocaml
    BENCH_INDEXED "Array.create" len [1;10;100;1000] =
      (fun () -> Array.create ~len 0)
    ```

    The above snippet measures the time taken to create arrays of
    different length.  Indexed tests are useful in highlighting
    non-linearities in the execution time of functions.

    We can group benchmarks together into modules and the output of
    `inline_benchmarks_runner` will reflect this grouping.

    ```ocaml
    BENCH_MODULE "Blit tests" = struct

      ..some benchmarks..

    end
    ```

    For examples of all of the above see `core_gc.ml` and `core_array.ml`.

    Only the generated `inline_benchmarks_runner.exe` depends on
    `Core_bench` and other libraries.  The library that includes the the
    benchmarks itself does not have a dependency on `Core_bench`.  Doing
    this is important so that we can add benchmarks to `Core` and still
    avoid cyclic dependencies.  Finally, it is important to note that
    adding inline benchmarks should have little effect on the execution or
    module initialization time.

