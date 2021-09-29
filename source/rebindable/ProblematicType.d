/// A deliberately problematic type for lifetime, constness, etc.
module rebindable.ProblematicType;

/**
 * A deliberately problematic type for lifetime, constness etc.
 *
 * Use to test containers like so:
 *
 * ---
 * int refs;
 * int* refsPtr = () @trusted { return &refs; }();
 * ... do things with ProblematicType(refsPtr) ...
 * assert(refs == 0);
 * ---
 */
public struct ProblematicType
{
    import std.datetime : SysTime;

    immutable int[] i;

    SysTime st;

    @disable this();

    bool properlyInitialized = false;

    invariant (properlyInitialized);

    void opAssign(ProblematicType)
    {
        assert(false);
    }

    // count references to confirm that every constructor call matches one destructor call
    int* refs;

    this(int* refs) pure @safe @nogc
    {
        this.properlyInitialized = true;
        this.refs = refs;
        (*refs)++;
    }

    this(this) pure @safe @nogc
    {
        (*refs)++;
    }

    // Since a destructor is defined, we will definitely
    // assert out if the .init value is ever destructed.
    ~this() pure @safe @nogc
    in (refs)
    out (; *refs >= 0)
    {
        (*refs)--;
    }
}
