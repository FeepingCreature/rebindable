/// `Rebindable!T` is a container for `T` that permits managing `T`'s lifetime explicitly.
module rebindable.Rebindable;

import rebindable.DeepUnqual;
import std.traits;

/// `Rebindable!T` is a container for `T` that permits managing `T`'s lifetime explicitly.
public struct Rebindable(T)
{
    private DeepUnqual!T store;

    /// Construct a Rebindable from a value.
    public this(T value)
    {
        set(value);
    }

    /**
     * Get a reference to a previously stored value.
     * Note that it is vital to not expose this reference to the user, if T may contain immutable fields by value!
     */
    public ref CopyConstness!(This, T) get(this This)() @nogc nothrow pure @trusted
    {
        return *cast(typeof(return)*) &this.store;
    }

    /**
     * Set the `Rebindable` to a new value.
     *
     * Any existing stored value is *not* freed!
     * You must free it manually with `destroy!false(rebindable.get);`.
     *
     * The passed value is copied.
     */
    public void set(ref T value) @trusted
    {
        // Since DeepUnqual doesn't call destructors, we deliberately leak one copy.
        static union BlindCopy { T value; }
        BlindCopy copy = BlindCopy(value);
        this.store = *cast(DeepUnqual!T*) &copy;
    }
}

///
unittest
{
    import rebindable.Rebindable : Rebindable;

    struct DataStructure(T)
    {
        private Rebindable!T store;

        this(T value)
        {
            this.store.set(value);
        }

        ~this()
        {
            destroy!false(this.store.get);
        }

        T get()
        {
            return this.store.get;
        }

        void set(T value)
        {
            destroy!false(this.store.get);
            this.store.set(value);
        }
    }

    DataStructure!(const int) ds;

    ds.set(5);
    assert(ds.get == 5);
}
