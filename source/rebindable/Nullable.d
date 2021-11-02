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
    public CopyConstness!(This, T) get(this This)()
    {
        assert(!isNull, "Attempted Nullable.get of empty Nullable");
        return payload.get;
    }

    /**
     * Get the value stored previously.
     * If no value is stored, `default` is returned.
     */
    public CopyConstness!(This, T) get(this This)(T default_)
    {
        if (isNull)
        {
            return default_;
        }
        return payload.get;
    }

    /// Assign a new value.
    public void opAssign(T value)
    {
        nullify;
        payload.set(value);
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

@nogc pure @safe unittest
{
    import rebindable.ProblematicType : ProblematicType;

    Nullable!int a;
    a = 3;
    assert(a.get == 3);

    Nullable!(const int) b;
    assert(b.get(3) == 3);
    b = 7;
    assert(b.get == 7);
    assert(b.get(3) == 7);

    int refs;
    int* refsPtr = () @trusted { return &refs; }();
    {
        // construct
        auto c = Nullable!ProblematicType(ProblematicType(refsPtr));
        assert(refs == 1);

        // reassign
        c = ProblematicType(refsPtr);
        assert(refs == 1);
        assert(c.get.properlyInitialized);

        // release
        c.nullify;
        assert(refs == 0);
    }
    assert(refs == 0);
}
