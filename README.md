# What is this?

`rebindable` is a D library of data types that work for any type, regardless of constness.

Its primary module is `rebindable.Rebindable`, with `Rebindable!T`, a type that takes an arbitrary type parameter `T`
and assumes control over its lifetime. You can use `rebindable.set(value)` and `rebindable.get` to interact with
the contained value.

This is done using helper type, `rebindable.DeepUnqual`, that takes an arbitrary type `T` and produces a
"primitive mutable type", of an "equivalent" type to `T` - with pointers in all the right places so that
when you allocate an array of it, the garbage collector will still scan its actual references and skip
non-pointer data.

At the same time, this type will be freely reassignable without running any lifetime functions: constructors,
destructors, copy constructors etc.

Reassignment will work even if the given type is immutable or contains immutable fields.

This can be useful when writing data structures that work with immutable types, but should not themselves
be immutable.

`rebindable` also contains `rebindable.Nullable`, a demo implementation of `Nullable` on top of `Rebindable`.

# Warning

`rebindable.get` returns a ref value. **Do not** expose this reference to the user! If you overwrite the
`rebindable` after taking a pointer to a returned `immutable` field, the user will observe `immutable`
memory changing, thus destroying any const guarantee.

Returning by value is fine.

# Example usage

### rebindable.Rebindable

```
import rebindable.Rebindable;

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

```

### rebindable.DeepUnqual

```
import rebindable.DeepUnqual;

static assert(is(DeepUnqual!int == int));
static assert(is(DeepUnqual!(const int) == int));
static assert(hasIndirections!(DeepUnqual!(void delegate())));
```

### rebindable.Nullable

```
import rebindable.Nullable;

Nullable!(const int) ni;

assert(ni.isNull);

ni = 5;
assert(!ni.isNull);
assert(ni.get == 5);

ni.nullify;
assert(ni.isNull);

assert(ni == Nullable!(const int)());
```

# Example

# But... why?

There is actually no good way in D today to create a type that is "like another type, but reassignable and
also its destructor is not run on scope exit." My post "The Turducken Type Technique" (
  https://forum.dlang.org/thread/ekbxqxhnttihkoszzvxl@forum.dlang.org ) was aimed at this goal, but somebody
recently pointed out that it's undefined behavior to have a data type allocated with an immutable member that is
cast to mutable. I have no reason to expect that to not hold when the data type is hidden in a union.

Hence `DeepUnqual`: a data type of the same layout, but with no immutability at all.

Is this good? No. Heck no, this is terrible code. I hate it. But I believe it's semantically valid, and I don't see
how we are supposed to use immutable types at all, practically, without it. So might as well put it out here
for review and improvement.

Hey, maybe somebody has a better idea.

# Is this safe?

Well, it's `@safe` so long as you `@trusted` me. :-)

Nothing with this amount of pointer casting can truly be called safe. It's safe *so far as I know*, provided that you:

- never expose a `DeepUnqual` of an immutable type by reference
- always match up assignments (see `rebindable.Nullable`) with `destroy` calls.

You can use `rebindable.ProblematicType` to test your container implementation for issues - compare the
`rebindable.Nullable` unittests.
