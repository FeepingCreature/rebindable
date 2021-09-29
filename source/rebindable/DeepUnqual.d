module rebindable.DeepUnqual;

import std.meta;
import std.traits;
import std.typecons;

/**
 * `DeepUnqual!T` is a data type that is equivalent to `T` in terms of size, alignment, and GC properties,
 * except that it can be freely reassigned.
 *
 * All special methods of T, such as constructors, destructors and overloads, are lost.
 */
public template DeepUnqual(T)
{
    alias DeepUnqual = DeepUnqualImpl!T;

    static assert(T.sizeof == DeepUnqual.sizeof);
    static assert(T.alignof == DeepUnqual.alignof);
    static assert(hasIndirections!T == hasIndirections!DeepUnqual);
}

private template DeepUnqualImpl(T)
{
    static if (is(T == struct))
    {
        static if (anyPairwiseEqual!(staticMap!(offsetOf, T.tupleof)))
        {
            // Struct with anonymous unions detected!
            // Danger, danger!
            // Fall back to void[].
            align(T.alignof)
            struct DeepUnqualImpl
            {
                void[T.sizeof] data;
            }
        }
        else
        {
            align(T.alignof)
            struct DeepUnqualImpl
            {
                staticMap!(DeepUnqual, typeof(T.init.tupleof)) fields;
            }
        }
    }
    else static if (is(T == union) || isAssociativeArray!T)
    {
        align(T.alignof)
        struct DeepUnqualImpl
        {
            static if (hasIndirections!T)
            {
                void[T.sizeof] data;
            }
            else
            {
                // union of non-pointer types?
                ubyte[T.sizeof] data;
            }
        }
    }
    else static if (is(T == class) || is(T == interface) || is(T == function) || is(T : U*, U))
    {
        alias DeepUnqualImpl = void*;
    }
    else static if (is(T : K[], K))
    {
        struct DeepUnqualImpl
        {
            size_t length;
            void* ptr;
        }
    }
    else static if (is(T == delegate))
    {
        struct DeepUnqualImpl
        {
            void* data;
            void* funcptr;
        }
    }
    else static if (is(T == enum))
    {
        alias DeepUnqualImpl = DeepUnqual!(OriginalType!T);
    }
    else static if (staticIndexOf!(typeof(cast() T.init),
        bool, byte, ubyte, short, ushort, int, uint, long, ulong,
        char, wchar, dchar, float, double, real, ifloat, idouble, ireal, cfloat, cdouble, creal) != -1)
    {
        alias DeepUnqualImpl = typeof(cast() T.init);
    }
    else static if (is(T == U[size], U, size_t size))
    {
        alias DeepUnqualImpl = DeepUnqual!U[size];
    }
    else
    {
        static assert(false, "Unsupported type " ~ T.stringof);
    }
}

private enum offsetOf(alias member) = member.offsetof;

private template anyPairwiseEqual(T...)
{
    static if (T.length == 0 || T.length == 1)
    {
        enum anyPairwiseEqual = false;
    }
    else static if (T.length == 2)
    {
        enum anyPairwiseEqual = T[0] == T[1];
    }
    else
    {
        enum anyPairwiseEqual = T[0] == T[1] || anyPairwiseEqual!(T[1 .. $]);
    }
}
