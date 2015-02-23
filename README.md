Pa\_bench is a syntax extension that helps writing in-line micro-benchmarks in ocaml code.

Building a runner executable
----------------------------

Inline benchmarks are embed with the normal OCaml code of libraries
or program. To run them you need to pass a _special_ first argument to
any program and call a report function.

For instance here is how you can build and run the inline benchmarks
for the `core_kernel` library:

    echo 'Inline_benchmarks.Runner.main ~libname:"core_kernel"' > runner.ml
    ocamlfind ocamlopt -package core_kernel,str,core_bench.inline_benchmarks \
      -thread -linkpkg -linkall runner.ml -o runner.exe
    ./runner.exe -benchmarks-runner

the `libname` matches the argument of the `-pa-ounit-lib` command-line
option of the [pa_ounit](https://github.com/janestreet/pa_ounit)
syntax extension.

For instance if you have a `bench.ml` file with some inline
benchmarks, you could compile it as follow:

    ocamlfind ocamlopt -syntax camlp4o \
      -package pa_bench,pa_bench.syntax \
      -ppopt -pa-ounit-lib -ppopt foo -c bench.ml

And them follow the same process as for `core_kernel`:

    echo 'Inline_benchmarks.Runner.main ~libname:"foo"' > runner.ml
    ocamlfind ocamlopt -package str,core_bench.inline_benchmarks \
      -thread -linkpkg -linkall runner.ml -o runner.exe
    ./runner.exe -benchmarks-runner

Overview
--------

The benchmarks are run with
[core_bench](https://github.com/janestreet/core_bench) which is very
good at estimating the costs of shortlived computations of the order
to 1ns to about 100ms. One can specify a benchmark using the following
syntax:

```ocaml
BENCH "name" = expr
```

In the above, the value of `expr` is ignored. This creates a benchmark
for `expr`, that is run using a runner. This workflow is similar to
that of inline unit tests.

For example, if you were to write the following into `foo.ml`:

```ocaml
BENCH "minor_words" = minor_words ()
BENCH "major_words" = major_words ()
BENCH "promoted_words" = promoted_words ()
BENCH "minor_collections" = minor_collections ()
BENCH "major_collections" = major_collections ()
BENCH "heap_words" = heap_words ()
BENCH "heap_chunks" = heap_chunks ()
BENCH "compactions" = compactions ()
BENCH "top_heap_words" = top_heap_words ()
BENCH "stat" = stat ()
BENCH "quick_stat" = quick_stat ()
BENCH "counters" = counters ()
```

Then you could build a runner and execute it as follow:

```
$ ./runner.exe -benchmarks-runner -q 1 -m gc
Estimated testing time 12s (12 benchmarks x 1s). Change using -quota SECS.
Name                     |     Time/Run | mWd/Run | Percentage
-------------------------|--------------|---------|-----------
foo.ml:minor_words       |       4.06ns |         |           
foo.ml:major_words       |       3.78ns |         |           
foo.ml:promoted_words    |       3.52ns |         |           
foo.ml:minor_collections |       3.52ns |         |           
foo.ml:major_collections |       3.52ns |         |           
foo.ml:heap_words        |       3.51ns |         |           
foo.ml:heap_chunks       |       3.51ns |         |           
foo.ml:compactions       |       3.51ns |         |           
foo.ml:top_heap_words    |       3.53ns |         |           
foo.ml:stat              | 240_815.86ns |  23.44w |    100.00%
foo.ml:quick_stat        |      92.30ns |  23.00w |      0.04%
foo.ml:counters          |      33.32ns |  10.00w |      0.01%
```

Typically a library will have hundreds of benchmarks while you care
only about a few of them at any point in time. The -m REGEX says that
we care to run only the benchmarks that match the REGEX. Here -q 1
specifies that we allow each benchmark one second worth of testing
time.

BENCH_FUN, BENCH_INDEXED and BENCH_MODULE
-----------------------------------------

There are three additional syntactic forms that are useful in various
cases. One can specify benchmarks that require some initialization
using `BENCH_FUN`. For example:

```ocaml
BENCH_FUN "name" =
  let t = create () in
  (fun () -> test_something t)
```

The function returned on the rhs of `BENCH_FUN` should have type `unit
-> unit`. One can specify benchmarks that have a variable parameter
using `BENCH_INDEXED`. Indexed tests are useful in highlighting
non-linearities in the execution cost of functions. For example:

```ocaml
BENCH_INDEXED "name" [variable] [values] =
  (fun () -> [.. expression that uses variable..] )
```

We can group benchmarks together into modules and the output of a
runner will reflect this grouping. Unlike ordinary modules, any top
level effects in `BENCH_MODULE` sections are executed only when
micro-benchmarks are run.

```ocaml
BENCH_MODULE "Blit tests" = struct
   ...
end
```
