import Adapt: adapt

"""
    children(x)

    Returns the direct children of the given tree-like value `x`.

"""
children(x) = ()

"""
    mapchildren(f, x)

    Returns a value similar to `x`, but whose children have been transformed by
    the function `f`.
"""
mapchildren(f, x) = x

children(x::Tuple) = x
mapchildren(f, x::Tuple) = map(f, x)

function treelike(T, fs = fieldnames(T))
  @eval begin
    children(x::$T) = ($([:(x.$f) for f in fs]...),)
    mapchildren(f, x::$T) = $T(f.(children(x))...)
    adapt(T, x::$T) = mapchildren(x -> adapt(T, x), x)
  end
end

isleaf(x) = isempty(children(x))

function mapleaves(f, x; cache = ObjectIdDict())
  haskey(cache, x) && return cache[x]
  cache[x] = isleaf(x) ? f(x) : mapchildren(x -> mapleaves(f, x, cache = cache), x)
end

export mapparams
@deprecate mapparams(f, x) mapleaves(f, x)

using DataFlow: OSet

function prefor(f, x; seen = OSet())
  x ∈ seen && return
  f(x)
  foreach(x -> prefor(f, x, seen = seen), children(x))
  return
end

"""
    params(m)

    Returns an array of all independant parameters in the given model `m`.
"""
function params(m)
  ps = []
  prefor(p ->
    Tracker.istracked(p) && Tracker.isleaf(p) &&
      !(p in ps) && push!(ps, p),
    m)
  return ps
end

params(m...) = params(m)
