# Euphoria Programming Language

**Euphoria** is a powerful but easy-to-learn and easy-to-use programming language. It has a simple syntax and structure with consistent rules, and is also easy to read. You can quickly, and with little effort, develop applications big and small for Windows and UNIX variants (Linux, FreeBSD, and OS X).

Euphoria was first released as _shareware_ way back in 1993. Nowadays, it is being developed as an open source project that is community driven and maintained by the [OpenEuphoria Group](http://openeuphoria.org/). Its use of simple English words rather than punctuation and symbols enables you to quickly read the source code and understand it.

Euphoria is a general-purpose programming language with a large standard library making it usable for a variety of tasks.  Please read some sample code for yourself. The language has evolved into a sophisticated tool that can be used to develop web and console applications and supports a variety of native-only and cross-platform GUI toolkits.

Euphoria is one of the fastest interpreted languages around. For even more speed and easy distribution, Euphoria also includes an integrated Euphoria-to-C translator. Euphoria provides subscript checking, uninitialized variable checking, garbage collection, and numerous other run-time checks, and is still _extremely_ fast.

## Language Overview

* Routines are declared as either a `function` _(returns a value)_ or a `procedure` _(does not return a value)_.
* Constants are declared with `constant` _(for any object type)_ or `enum` _(for integer enumerations only)_.
* Variables are declared as either an `atom` _(any numeric value)_ or a `sequence` _(a dynamic array of atoms or sequences)_.
* Variables can be declared as an `object` to hold any value dynamically. Use the `integer` type for simple counting.
* Sequence element numbers start at `1`, _because counting should be easy_.
* Strings are stored simply as sequences of atoms of character values.

## Sample Code

### Hello World

```euphoria
include std/io.e

procedure main()
    
    puts( STDOUT, "Hello, world!\n" )
    
end procedure

main()
```

#### Output

    Hello, world!

### Fibonacci Numbers

```euphoria
procedure main()
    
    integer f0 = 0
    integer f1 = 1
    
    -- ? prints to console
    ? f0
    ? f1
    
    while f1 < 100 do
        
        integer f = f0 + f1
        ? f
        
        f0 = f1
        f1 = f
        
    end while
    
end procedure

main()
```

#### Output

    0
    1
    1
    2
    3
    5
    8
    13
    21
    34
    55
    89
    144

### Atoms and integers

```euphoria
include std/io.e
include std/math.e

procedure main()
    
    atom twopi = PI * 2
    atom halfpi = PI / 2
    integer myage = 42
    
    printf( STDOUT, "twopi = %0.10\n", {twopi} )
    printf( STDOUT, "halfpi = %g\n", {halfpi} )
    printf( STDOUT, "myage is %d\n", {myage} )
    
end procedure

main()
```

#### Output

    twopi = 6.2831853072
    halfpi = 1.5708
    myage is 42

### Strings and sequences

```euphoria
include std/io.e

procedure main()
    
    sequence numbers = {1,2,3,4,5}
    sequence timestwo = numbers * 2
    sequence myname = "Fred"
    
    print( STDOUT, numbers )
    print( STDOUT, timestwo )
    print( STDOUT, myname )
    printf( STDOUT, "my name is %s\n", {myname} )
    
end procedure

main()
```

#### Output

    {1,2,3,4,5}
    {2,4,6,8,10}
    {70,114,101,100} -- same as {'F','r','e','d'} or "Fred"
    my name is Fred
