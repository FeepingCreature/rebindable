module rebindable.Rebindable;

import rebindable.DeepUnqual;
import std.traits;

public struct Rebindable(T)
{
    private DeepUnqual!T store;

    ///
    public this(T value)
    {
        set(value);
    }

    ///
    public ref CopyConstness!(This, T) get(this This)() @nogc nothrow pure @trusted
    {
        return *cast(typeof(return)*) &this.store;
    }

    ///
    public void set(ref T value) @trusted
    {
        // Since DeepUnqual doesn't call destructors, we deliberately leak one copy.
        static union BlindCopy { T value; }
        BlindCopy copy = BlindCopy(value);
        this.store = *cast(DeepUnqual!T*) &copy;
    }
}
