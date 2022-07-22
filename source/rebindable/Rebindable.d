/// `Rebindable!T` is a container for `T` that permits managing `T`'s lifetime explicitly.
module rebindable.Rebindable;

import rebindable.DeepUnqual;
import std.traits;

/**
 * `Rebindable!T` is a container for `T` that permits managing `T`'s lifetime explicitly.
 */
public struct Rebindable(T)
{
    private DeepUnqual!T store;

    /// Construct a Rebindable from a value.
    public this(T value)
    {
        set(value);
    }

    /**
     * Move-return the stored value by value.
     * This is equivalent to `get` followed by `destroy`.
     *
     * This operation invalidates the `Rebindable`.
     * Until `set` is called again, `move` and `get` are undefined.
     */
    public CopyConstness!(This, T) move(this This)() @safe
    {
        auto result = get;

        destroy;
        return result;
    }

    /**
     * Replace a currently stored value with a new value.
     * This is equivalent to `destroy` followed by `set`.
     */
    public void replace()(T value) @safe
    {
        destroy;
        set(value);
    }

    /**
     * Get a copy of a previously stored value.
     */
    public CopyConstness!(This, T) get(this This)() @nogc nothrow pure @safe
    {
        return reference;
    }

    /**
     * Set the `Rebindable` to a new value.
     * Calling this function while an existing value is stored is undefined.
     * The passed value is copied.
     */
    public void set(T value) @trusted
    {
        // Since DeepUnqual doesn't call destructors, we deliberately leak one copy.
        static union BlindCopy
        {
            T value;
        }

        BlindCopy copy = BlindCopy(value);
        this.store = *cast(DeepUnqual!T*)&copy;
    }

    /**
     * Destroys the stored value.
     * This is equivalent to a variable going out of scope.
     */
    public void destroy() @trusted
    {
        import std.typecons : No;

        static if (is(T == class) || is(T == interface))
        {
            reference = null;
        }
        else
        {
            // call possible struct destructors
            .destroy!(No.initialize)(reference);
        }
    }

    private ref CopyConstness!(This, T) reference(this This)() @nogc nothrow pure @trusted
    {
        return *cast(typeof(return)*)&this.store;
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
            this.store.destroy;
        }

        T get()
        {
            return this.store.get;
        }

        void set(T value)
        {
            this.store.replace(value);
        }
    }

    DataStructure!(const int) ds;

    ds.set(5);
    assert(ds.get == 5);
}

// set and destroy
unittest
{
    import rebindable.ProblematicType : Fixture, ProblematicType;

    with (Fixture())
    {
        Rebindable!ProblematicType container;

        {
            auto value = problematicType;

            assert(references == 1);
            container.set(value);
        }
        assert(references == 1);
        container.destroy;
        assert(references == 0);
    }
}

// set and replace
unittest
{
    import rebindable.ProblematicType : Fixture, ProblematicType;

    with (Fixture())
    {
        Rebindable!ProblematicType container;

        container.set(problematicType);
        assert(references == 1);
        {
            auto value = container.get;

            container.replace(problematicType);
            assert(references == 2);
        }
        assert(references == 1);
        container.destroy;
        assert(references == 0);
    }
}

// set and move
unittest
{
    import rebindable.ProblematicType : Fixture, ProblematicType;

    with (Fixture())
    {
        Rebindable!ProblematicType container;

        container.set(problematicType);
        assert(references == 1);
        {
            auto value = container.move;

            assert(references == 1);
        }
        assert(references == 0);
    }
}
