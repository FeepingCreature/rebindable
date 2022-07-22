module rebindable.AssocArray;

import rebindable.Rebindable;
import std.algorithm;
import std.traits : hasElaborateDestructor;
import std.typecons : Nullable, tuple;

version (unittest) import rebindable.ProblematicType : Fixture, ProblematicType;

/**
 * This generic data type implements an associative array, like D's built-in `V[K]`.
 * As opposed to the built-in associative arrays, it supports updating immutable values for keys.
 */
struct AssocArray(K, V)
{
    private Rebindable!V[K] store;

    public this(typeof(null) null_)
    {
    }

    public void opAssign(typeof(null) null_)
    {
        this.store = null;
    }

    /*
     * What's all this `K mutableKey = cast(K) key;` stuff?
     * Consider https://issues.dlang.org/show_bug.cgi?id=12491 - associative array keys
     * must be immutable, but nobody particularly wants to enforce this on the typesystem
     * level. So for associative array compatible, we do likewise - accept any constness
     * of key, and cast to K, safe in the assumption that it needs to be treated as
     * immutable by the caller anyways.
     */
    /// Return whether the key is in the hashmap.
    public bool opBinaryRight(string op = "in")(const K key) const
    {
        K mutableKey = cast(K) key;

        if (mutableKey in this.store)
        {
            return true;
        }
        return false;
    }

    /// Return the stored value for `key` if present, or `default_`.
    public V get(this This)(const K key, lazy V default_)
    {
        K mutableKey = cast(K) key;

        if (auto ptr = mutableKey in this.store)
        {
            return ptr.get;
        }
        return default_;
    }

    /**
     * Return the stored value for `key`.
     * Throws: `RangeError` if `key` has no stored value.
     */
    public V opIndex(this This)(const K key, const string file = __FILE__, const size_t line = __LINE__)
    {
        import core.exception : RangeError;

        K mutableKey = cast(K) key;

        if (auto ptr = mutableKey in this.store)
        {
            return ptr.get;
        }
        throw new RangeError(file, line);
    }

    /// Replace the stored value for `key` with `value`.
    public void opIndexAssign(V value, const K key)
    {
        K mutableKey = cast(K) key;

        if (auto ptr = mutableKey in this.store)
        {
            ptr.replace(value);
        }
        else
        {
            this.store[mutableKey] = Rebindable!V(value);
        }
    }

    /**
     * Remove the stored key-value pair for `key`.
     * If `key` is not stored, return false.
     */
    public bool remove(const K key)
    {
        K mutableKey = cast(K) key;

        if (auto ptr = mutableKey in this.store)
        {
            ptr.destroy;
            this.store.remove(mutableKey);
            return true;
        }
        return false;
    }

    ///
    public size_t length() const
    {
        return this.store.length;
    }

    /// Return `array[key].nullable` if `key` is in the array, else null.
    public Nullable!V getNullable(this This)(const K key)
    {
        K mutableKey = cast(K) key;

        if (mutableKey in this)
        {
            return Nullable!V(this[mutableKey]);
        }
        return Nullable!V();
    }

    /**
     * Iterate over the associative array by key/value pairs.
     */
    public auto byKeyValue(this This)()
    {
        return this.store.byKeyValue.map!(a => tuple!("key", "value")(a.key, a.value.get));
    }

    /**
     * Iterate over the associative array by value.
     */
    public auto byValue(this This)()
    {
        return this.store.byValue.map!"a.get";
    }

    /**
     * Iterate over the associative array by key.
     */
    public auto byKey(this This)()
    {
        return this.store.byKey;
    }

    /**
     * Delete all values in the associative array.
     */
    public void clear()
    {
        while (!this.store.byKey.empty)
        {
            remove(this.store.byKey.front);
        }
    }
}

// set, replace, remove value
unittest
{
    with (Fixture())
    {
        AssocArray!(int, ProblematicType) assocArray;

        assocArray[0] = problematicType;
        assert(references == 1);

        assocArray[0] = problematicType;
        assert(references == 1);

        assocArray.remove(0);
        assert(references == 0);
    }
}

// scope runs out
unittest
{
    with (Fixture())
    {
        {
            AssocArray!(int, ProblematicType) assocArray;

            assocArray[0] = problematicType;
            assert(references == 1);
        }
        /**
         * There is an open question regarding how we are supposed to clean up stored values.
         * For now, we just leak them.
         */
        // assert(references == 0);
    }
}

// associative array with class value
unittest
{
    AssocArray!(int, Object) assocArray;
    auto object = new Object;

    assocArray[0] = object;
    assert(assocArray[0] is object);
}

// associative array with key declared mutable
unittest
{
    struct S
    {
        int[] data;
    }

    AssocArray!(S, int) assocArray;

    assocArray[S([0])] = 5;
    assert(assocArray[S([0])] == 5);
}
