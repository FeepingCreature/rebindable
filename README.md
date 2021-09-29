# What is this?

`rebindable` is a D library of data types that work for any type, regardless of constness.

It contains a helper type, `rebindable.DeepUnqual`, that takes an arbitrary type `T` and produces a "primitive mutable
type", of an "equivalent" type to `T` - with pointers in all the right places so that when you allocate an array of it,
the garbage collector will still scan its actual references and skip non-pointer data.

At the same time, this type will be freely reassignable without running any lifetime functions: constructors,
destructors, copy constructors etc.

Reassignment will work even if the given type is immutable or contains immutable fields.

This can be useful when attempting to write data structures that work with immutable types.

`rebindable` also contains `rebindable.Nullable`, a demo implementation of `Nullable` on top of `DeepUnqual`.

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

# Example usage

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
