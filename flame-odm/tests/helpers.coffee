ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

{ flatPaths } = require '@flame-odm/lib/helpers'

_ = require 'lodash'


describe 'helpers.flatPaths --', ->

  it 'leaves a flat object unchanged.', ->
    (assert (_.isEqual (flatPaths { a: 1, b: 2 }), { a: 1, b: 2 }))
    return

  it 'flattens a nested object into dotted paths.', ->
    (assert (_.isEqual (flatPaths { a: { b: 1 } }), { 'a.b': 1 }))
    return

  it 'flattens a deeply nested object.', ->
    out = (flatPaths { a: 1, b: { c: 2, d: { e: 3 } } })
    (assert (_.isEqual out, { a: 1, 'b.c': 2, 'b.d.e': 3 }))
    return

  it 'returns an empty object for an empty object.', ->
    (assert (_.isEqual (flatPaths {}), {}))
    return

  it 'keeps an empty object value rather than recursing into it.', ->
    (assert (_.isEqual (flatPaths { a: {} }), { a: {} }))
    return

  it 'does not recurse into array values.', ->
    (assert (_.isEqual (flatPaths { a: [ 1, 2 ] }), { a: [ 1, 2 ] }))
    return

  it 'preserves function values at their flattened path.', ->
    fn  = (t, d) -> t
    out = (flatPaths { a: { b: fn } })
    (assert (out['a.b'] == fn))
    return
