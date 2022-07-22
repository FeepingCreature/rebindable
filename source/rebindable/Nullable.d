/// A version of `std.typecons.Nullable` that reliably works with immutable data types.
module rebindable.Nullable;

import rebindable.Rebindable;
import std.traits;

/// A version of `std.typecons.Nullable` that reliably works with immutable data types.
struct Nullable(T)
{
    private bool isNull_ = true;

    private Rebindable!T payload;

    /// Construct a new `Nullable!T`.
    public this(T value)
    {
        this.isNull_ = false;
        this.payload.set(value);
    }

    /// Return true if the `Nullable!T` does not contain a value.
    public bool isNull() const nothrow pure @safe
    {
        return this.isNull_;
    }

    /**
     * Get the value stored previously.
     * It is undefined to call this if no value is stored.
     */
    public T get(this This)()
    {
        assert(!isNull, "Attempted Nullable.get of empty Nullable");
        return payload.get;
    }

    /**
     * Get the value stored previously.
     * If no value is stored, `default` is returned.
     */
    public T get(this This)(T default_)
    {
        if (isNull)
        {
            return default_;
        }
        return payload.get;
    }

    /**
     * Sets the stored value to a new value.
     * Any existing value is destroyed.
     */
    public void opAssign(T value)
    {
        if (!this.isNull_)
        {
            payload.replace(value);
        }
        else
        {
            payload.set(value);
        }
        this.isNull_ = false;
    }

    ///
    public void opAssign(Nullable!T source)
    {
        if (source.isNull)
        {
            nullify;
        }
        else
        {
            this = source.payload.get;
        }
    }

    /// If a value is stored, destroy it.
    public void nullify()
    {
        if (!this.isNull_)
        {
            this.payload.destroy;
            this.isNull_ = true;
        }
    }

    ///
    public bool opEquals(const Nullable other) const pure @safe
    {
        if (this.isNull != other.isNull)
        {
            return false;
        }
        if (this.isNull)
        {
            return true;
        }
        else
        {
            return payload.get == other.payload.get;
        }
    }

    /// Returns an equivalent Phobos Nullable instance.
    public Nullable!T toNullable(this This)()
    {
        if (this.isNull_)
        {
            return Nullable!T();
        }
        return Nullable!T(payload.get);
    }

    static if (hasElaborateDestructor!T)
    {
        ~this()
        {
            if (!isNull)
            {
                payload.destroy;
            }
        }
    }
}

///
@nogc pure @safe unittest
{
    Nullable!(const int) ni;

    assert(ni.isNull);

    ni = 5;
    assert(!ni.isNull);
    assert(ni.get == 5);

    ni.nullify;
    assert(ni.isNull);

    assert(ni == Nullable!(const int)());
}

///
pure @safe unittest
{
    Nullable!(immutable int[]) value;
    assert(value.isNull);

    value = [5].idup;
    assert(value.isNull == false);
    assert(value.get == [5]);

    value.nullify;
    assert(value.isNull == true);

    const constValue = Nullable!(immutable int[])([8]);

    assert(constValue.isNull == false);
    assert(constValue.get == [8]);
}

@nogc pure @safe unittest
{
    import rebindable.ProblematicType : Fixture, ProblematicType;

    Nullable!int a;
    a = 3;
    assert(a.get == 3);

    Nullable!(const int) b;
    assert(b.get(3) == 3);
    b = 7;
    assert(b.get == 7);
    assert(b.get(3) == 7);

    with (Fixture())
    {
        // construct
        auto c = Nullable!ProblematicType(problematicType);
        assert(references == 1);

        // reassign
        c = problematicType;
        assert(references == 1);
        assert(c.get.properlyInitialized);

        // release
        c.nullify;
        assert(references == 0);
    }
}


/**
 * Returns null if `nullable` is null, else `fun(nullable.get)`.
 * When `fun` returns a `Nullable`, reuses its null state.
 */
public auto apply(alias fun, T: Nullable!U, U)(const T nullable)
{
    import std.functional : unaryFun;

    alias ReturnType = typeof(unaryFun!fun(nullable.get));

    static if (is(ReturnType : Nullable!S, S))
    {
        alias Result = ReturnType;
    }
    else
    {
        alias Result = Nullable!ReturnType;
    }

    if (nullable.isNull)
    {
        return Result();
    }
    return Result(unaryFun!fun(nullable.get));
}

///
unittest
{
    Nullable!int a;

    assert(a.apply!(i => i * i) == Nullable!int());

    a = 5;

    assert(a.apply!(i => i * i) == Nullable!int(25));
}
