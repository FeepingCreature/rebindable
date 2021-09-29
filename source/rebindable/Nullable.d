module rebindable.Nullable;

import rebindable.DeepUnqual;
import std.traits;

/**
 * A version of std.typecons.Nullable that reliably works with immutable data types.
 */
struct Nullable(T)
{
    private bool isNull_ = true;

    private DeepUnqual!T payload_;

    ///
    public this(T value)
    {
        this.isNull_ = false;
        set(value);
    }

    ///
    public bool isNull() const nothrow pure @safe
    {
        return this.isNull_;
    }

    ///
    public CopyConstness!(This, T) get(this This)()
    {
        assert(!isNull, "Attempted Nullable.get of empty Nullable");
        return payload;
    }

    ///
    public void opAssign(T value)
    {
        nullify;
        set(value);
        isNull_ = false;
    }

    ///
    public void nullify()
    {
        if (!this.isNull_)
        {
            destroy!false(payload);
            this.isNull_ = true;
        }
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
            this = source.payload;
        }
    }

    ///
    public bool opEquals(const Nullable other) const nothrow pure @safe
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
            return payload == other.payload;
        }
    }

    private ref CopyConstness!(This, T) payload(this This)() @trusted
    {
        return *cast(typeof(return)*) &this.payload_;
    }

    private void set(ref T value) @trusted
    {
        // copy value, but do not destroy it (ensures lifetimes match up)
        static union BlindCopy { T payload; }
        BlindCopy copy = BlindCopy(value);
        payload_ = *cast(DeepUnqual!T*) &copy;
    }
}

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
    b = 7;
    assert(b.get == 7);

    int refs;
    int* refsPtr = () @trusted { return &refs; }();
    {
        auto c = Nullable!ProblematicType(ProblematicType(refsPtr));
        assert(refs == 1);

        c = ProblematicType(refsPtr);
        assert(refs == 1);
        assert(c.get.properlyInitialized);

        c.nullify;
        assert(refs == 0);
    }
    assert(refs == 0);
}
