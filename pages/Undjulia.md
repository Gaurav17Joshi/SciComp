+++
title = "Understanding Julia"
hascode = true
date = Date(2019, 1, 23)
rss = "A page on the heart of Julia"

tags = ["syntax", "code"]
+++

# Understanding Julia

Attach image

\toc

## Why Julia

Julia is a new language aimed at scientific computing. It is made to be both high level and fast.
Julia is a fast dynamic-typed language that just-in-time (JIT) compiles into native code using LLVM.

Julia uses the LLVM compiler, and yet is faster than many other languages, due to its language semantics which
allows a well-written Julia program to give more opportunities to the compiler to generate efficient code and memory layouts.

Julia has **three** main features that makes it a unique language to work with, specially in scientific computing:
* Speed
* Ease of Use
* Multiple Dispatch

### Speed 
Julia is fast as it bypasses any sort of intermediate representation and translate code into machine native code using LLVM compiler. Comparing this with R, that uses either FORTRAN or C, or Python, that uses CPython; and you'll clearly see that Julia has a major speed advantage over other languages that are common in data science and statistics. Julia exposes the machine code to LLVM's compiler which in turn optimizes code as it wishes.

### Ease of Use
Julia can be as fast as C while having a very simple and intelligible syntax.

This feature along with its speed is what Julia creators denote as "the two language problem" that Julia addresses. The "two language problem" is a very typical situation in scientific computing where a researcher or computer scientist devises an algorithm or a solution that she prototypes in an easy to code language (like Python) and, if it works she would code in a fast language that is not easy to code (C or FORTRAN).  

Julia comes to eliminate such situations by being the same language that you prototype (ease of use) and implement the solution (speed).

**Math**, julia code is closer to mathematical equations, as it lets us use unicode characters as variables or parameters. When you see code for an algorithm or for a mathematical equation you see **a one-to-one relation to code and math**. This is a powerful feature.

### Multiple Dispatach
The ability to define **function behavior** across many combinations of argument types via multiple dispatch. Multiple dispatch is a feature that allows a function or method to be dynamically dispatched based on the run-time (dynamic) type or, in the more general case, some other attribute of more than one of its arguments.

Multiple dispatch empower users to define their own types (if necessary) and also allows them to extend functions and types from other users to their own special use.

Attach video link

Also, to cap it off, all julia libraries are written in julia, using it own code, without calling any other language.

This part is taken from the excellent intro to julia from [Turing.jl website](https://storopoli.io/Bayesian-Julia/pages/01_why_Julia/)

## Understanding fast julia code

This part is taken from [sciml lectures](https://book.sciml.ai/notes/02-Optimizing_Serial_Code/)


This part will explain what makes code slow and how to avoid these pitfalls. It will also go into the heart of julia and explain some key properties of the language.

The 3 main points to keep in mind to write fast julia code is
1. Use as few loops as possible
2. Try to fuse as many loops as possible
3. Reuse cache arrays as much as possible 

We will explore some important features of the Julia library to understand fast and compiler specific code:-

### Matrix Orientation

The processor works in a chain, so it before hand tries to guess which blocks of memory, we might be calling next. Thus our algorithms are faster if we grab memory along the cache line. In Julia (also Fortran, Matlab), we have a matrix represented as a cache line along the column axis, ie we take the first column traverse down it, then move onto the next and so on. 

Insert image 

Thus grabbing values column wise speeds up compared to row wise as we have fewer cache misses.

Here is an example for a column wise implimentation of matrix addition, we will keep on imporving on this code.
```julia:./code/undjulia01
# Code for Fast matrix add along the column
A = rand(100,100)
B = rand(100,100)
C = rand(100,100)
using BenchmarkTools
function faster_matrix_add!(C,A,B)
  for j in 1:100, i in 1:100
    C[i,j] = A[i,j] + B[i,j]
  end
end
@btime faster_matrix_add!(C,A,B)
```

\output{./code/undjulia01}

### Stack and Heap

Stack and heap and two ways of arranging data in the memory. 

Making a stack requires a static allocation (We should be sure of the data type, eg array of float-32's). As it is ordered, it is very clear where things are in the stack hense, it can be accessed very quickly. 

Heaps are used when we do not know the size of variable at the compile time. Heaps are a collection of pointers, which point to data locations which has a block to specify the type of data and then the actual data, or further pointers, generated during runtime. As is obvious, making a heap has a lot of cache misses and calls further down to L2, L3 caches, thus compromising on runtime.

The **problem**, with stack is that, we need to have the data-type before hand, and it does not work very well for large arrays.

> Static arrays.jl is used to make static allocations to arrays, objects, using @Svector macros

**Macros**, are pieces of code that act on code

This code block shows the use of Static arrays to convert the array val to a static object with known size(bits). Had we not used static the array could not have proved at compile time its size, and val would have been heap allocated, but Static Arrays libraries can convert it into a static data block by looking at the contents of the array.

```julia:./code/undjulia2
using StaticArrays
function static_inner_alloc!(C,A,B)
  for j in 1:100, i in 1:100
    val = @SVector [A[i,j] + B[i,j]]
    C[i,j] = val[1]
  end
end
@btime static_inner_alloc!(C,A,B)
```

\output{./code/undjulia2}

### Mutations

Many times you do need to write into an array, so how can you write into an array without performing a heap allocation? The answer is mutation. Mutation is changing the values of an already existing array. In that case, no free memory has to be found to put the array (and no memory has to be freed by the garbage collector).

This is what we did in the above codes also, and it reduces heap allocations than first making a array using `C = similar(A)` and then allocating.

**Using !(Bang):**
The bang symbol is an important part of function labeling. When we are reusing a cache array (speed up things), and we are allocating the data to an already present matrix(data block), we put a **!**, as a convention to represent that we made the changes to the first input of this function. (This makes code clearer). 

### Broadcasting

Broadcasting is a method by which we can avoid writing loops by using **. dot**, to signify doing the operation over all the individual elements (along best cache lines (ie column major)). In other programming languages (python), it is also called as "Vectorisation", and is necessary as in those languages, the loops has a lot of overhead.

While julia does not have a lot of overhead in loops, **broadcasting still speeds up**  mainly bacause of:
1. We do not have to use any temporary variables `tmp = A .+ B` to store the intermediates.
2. In loops we do `temp[i] = A[i] + B[i]`, and this always checks if the bounds are breached, hence slower code. `@inbounds` can help with this though.

Code implementations of adding matrices using Broadcasting, and it cuts the time even further.

```julia:./code/undjulia03
fused(A,B) = A .+ B 
@btime fused(A,B);
```

\output{./code/undjulia03}

```julia:./code/undjulia04
D = similar(A)
fused!(D,A,B) = (D .= A .+ B )
@btime fused!(D,A,B);
```
\output{./code/undjulia04}

> In Julia, we can index a matrix with single index by reading it column wise. A[202] for 100x100 matrix is column 3 row 2 term (2,3)

Also note that Julia allows for **broadcasting the call () operator** as well. .() will call the function element-wise on all arguments, so sin.(A) will be the elementwise sine function. 

### Summary
* Avoid cache misses by reusing values (Mutation)
* Iterate along columns (prevents cache misses)
* Avoid heap allocations in inner loops which occur when the size of things is not proven at compile-time
* Use fused broadcasts (with mutated outputs) to avoid heap allocations
* Array vectorization confers no special benefit in Julia because Julia loops are as fast as C or Fortran (only small speedup)
* Use views instead of slices (produces copies) when applicable. 
* Avoiding heap allocations is most necessary for O(n) algorithms or algorithms with small arrays, (in more slower algos, it gets overshadowed)
* Use StaticArrays.jl to avoid heap allocations of small arrays in inner loops

## Compilation and Type inference in Julia

### Jit compilation

As wikipedia puts it, Jit (Just in Time) compilation is is compilation of code during execution of a program (at run time) rather than before execution (compile time). JIT compiler continuously analyses the code being executed and identifies parts of the code where the speedup gained from compilation or recompilation would outweigh the overhead of compiling that code. 

The jit compiler gets both the **data type**, and **array size**, (object size) of the code at the run time (we have put the values), hense it compiles the code, its functions at the compile time based on this knowledge. Just like the JAX jit compilation does. 

**Note:** llvm is the jit compiler in constrast to the gcc compiler u. In a compile time compilation, the code sets pointers for various objects and arrays, which makes it slower due to heap allocation, but when we compile at runtime, we already get the data type and size, and can use proper stacks for the code, hense jit compilation is faster.

### Julia's Features

Julia is not fast due to being JIT compiled, rather it is fast due to two important features:

* Type inference
* Type specialization in functions

These two features combine and give rise to Julia's core design feature: **Multiple dispatch**.

These can be **summed up** by saying that Julia's type inference allows it get the variable types during run time, and Julia's type specialisation in function, allows it to propagate types and create different functions for different given types. Hense, it knows the input and can identify the type of output (for functions in functions), and it uses this to build a very efficient assembly code because it knows exactly what the types will be at every step.

Multiple dispatch together with the flexible parametric type system give Julia its ability to abstractly express high-level algorithms decoupled from implementation details. As julia is always specializing its types on each function, if those functions themselves can infer the output, then the entire function can be inferred and generate optimal code, which is then optimized by the compiler and out comes an efficient function. If types can't be inferred, Julia falls back to a slower "Python" mode. 

Users get control over this specialization process through multiple dispatch, since it allows adding new options without any runtime cost.

> Julia basically decode the code during runtime, completing understanding and optimising all type and memory allocations.

### Type Inference

All data in a code has some data type and a program has to figure it out associate memory to it, carry out calculation, use it for functions. Some languages are more explicit about said types, while others try to hide the types from the user.

**What Julia does**: Before the Jit compilation, Julia runs a type inference algorithm which finds out types of variables. This is a hybrid method solution, where we do not have to explicitly put types for functions like c++. 

Also as jit compilation the data types are figured out, and due of type propagation of functions all variables, outputs data and sizes are known, reducing heap allocations and mutiple cache misses drastically.

**Julia Code**: 
```julia:./code/undjulia05
a = 2; b = 4
a + b
```
\output{./code/undjulia05}

**Result**: Julia does not have the discoraging syntax of c++, but still figures out the types well.

**What Python does**: Python allows the user to define variables without specifying, and identifies types during runtime. This leads to lots of type identification during function call at each step, leading code to slow down.

**Python Code**:
Similar to the Julia code

**Result**: Nice interface, but slow code

**What C++ does**: C++, asks users to explicity provide the types for all the arguments in its functions.

**C++ Code**:
```
void add(double *a, double *b, double *c, size_t n){
  size_t i;
  for(i = 0; i < n; ++i) {
    c[i] = a[i] + b[i];
  }
}
```

### Type Specialisation in Functions
Simply Stated: Julia is able to propagate type inference through functions.

Julia interprets functions as generic functions and produces new functions based on the given type of inputs
We can see this by examining the LLVM IR (IR is the Intermediate Representation)

```julia:./code/undjulia06
using InteractiveUtils
f(x,y) = x+y
@code_llvm f(2,5)
```
\output{./code/undjulia06}

```julia:./code/undjulia07
@code_llvm f(2.0,5)
```
\output{./code/undjulia07}

The Function takes in the inputs, and then it encounters a +, and we have multiple dispatched the ouputs for +, so we know the type of outputs, hense for functions using functions, we can completely go through and produce specific functions for the input data type, and get the output data type also.

> @code_llvm gives the intermediate representation, @code_warntype types gives type inferencing

Example code for how julia deduces the output types of functions (shown using @code_warntype):

```julia:./code/undjulia08
function g(x,y)
  a = 4
  b = 2
  c = f(x,a)
  d = f(b,c)
  f(d,y)
end

@code_warntype g(2,5.0)
```
\output{./code/undjulia08}


### Multiple Dispatch
In a nutshell, multiple dispatch is writing a function in different ways for different types of inputs for all function arguments.

A function is an object that maps a tuple of arguments to an output, and we need to have functions for different data type of arguments, or different objects. A definition of one possible behavior for a function is called a **method**. the signatures of method definitions can be annotated to indicate the types of arguments in addition to their number, and more than a single method definition may be provided to a function. Thus, the overall behavior of a function is a patchwork of the behaviors of its various method definitions. If the patchwork is well designed, even though the implementations of the methods may be quite different, the outward behavior of the function will appear seamless and consistent.

The choice of which method to execute when a function is applied is called **dispatch**. Julia allows the dispatch process to choose which of a function's methods to call based on the number of arguments given, and on the types of all of the function's arguments. This is different than traditional object-oriented languages, where dispatch occurs based only on the **first argument**, which often has a special argument syntax, and is sometimes implied rather than explicitly written as an argument. Using** all of a function's arguments** to choose which method should be invoked, rather than just the first, is known as multiple dispatch.

There isnt any general way to construct such functions in python, and in c++, we have a similar thing as operator overloading (also template programming), 

Example code for multiple dispatch in julia

```julia:./code/undjuliam01
abstract type Pet end
struct Dog <: Pet
    name::String
end
struct Cat <: Pet
    name::String
end

function encounter(a::Pet, b::Pet)
    verb = meets(a, b)
    return println("$(a.name) meets $(b.name) and $verb")
end

meets(a::Dog, b::Dog) = "sniffs";
meets(a::Dog, b::Cat) = "chases";
meets(a::Cat, b::Dog) = "hisses";
meets(a::Cat, b::Cat) = "slinks";

fido = Dog("Fido");
rex = Dog("Rex");
whiskers = Cat("Whiskers");
spots = Cat("Spots");

encounter(fido, rex)
encounter(rex, whiskers)
encounter(spots, fido)
encounter(whiskers, spots)
```

\output{./code/undjuliam01}

> Note, in Julia all functions are written form the base, like +(x::llvm,y::llvm) = some llvm code

**Generic functions an Any type**

To control the types for multiple dispatch, there exists a hierarchy for types in julia, ie. Julia uses the more abstract definition if the exact combination is not present. 

**Any** is a maximal subtype of every Julia type, and a fallback for any inputs. (But, there must be a generic function for any to use otherwise type ambiguities may arise)

```julia:./code/undjuliaa01
f(x::Any,y::Any) = x+y
```
\output{./code/undjuliaa01}


**Ambiguities**



### One Hot Vector Example
This powerful example shows how useful mutiple dispatch is to just make the function for an new type for some argument and it works.


