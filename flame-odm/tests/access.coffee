ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

Access = require '@flame-odm/lib/access'

_ = require 'lodash'


describe 'Access --', ->

  it 'An Access can be created.', ->
    ok = false
    
    m =
      hello: [ 'a' ]
      global:
        world: [ 'a', 'b', 'c' ]
      thing:
        one: [ 'c' ]

    try
      a = (new Access m)
      ok = true
    catch
      _.noop()

    (assert ok)
    return

  it 'An Access can be used to screen an object by role.', ->
    ok = false

    m =
      a: [ 'a' ]
      b: { c: [ 'a', 'b', 'c' ]}
      d: { e: [ 'c' ]}

    a = (new Access m)

    obj =
      a: 1
      b: { c: 2 }
      d: { e: 3 }

    o = (a.screen obj, [ 'a' ])

    ok = (_.isEqual o, { a: 1, b: { c: 2 }})

    (assert ok)
    return

  it 'An Access can be used to generate a list of fields a role can access.', ->
    ok = false

    m =
      a: [ 'a' ]
      b: { c: [ 'a', 'b', 'c' ]}
      d: { e: [ 'c' ]}

    a = (new Access m)

    o = (a.fields [ 'c' ])

    ok = (_.isEqual o, [ 'b.c', 'd.e' ])

    (assert ok)
    return

  throws = (fn) ->
    try
      (fn())
      return false
    catch e
      return true

  it 'cannot be constructed from a non-object mask.', ->
    (assert (throws -> (new Access 5)))
    return

  it 'cannot be constructed when a field maps to a non-array.', ->
    (assert (throws -> (new Access { a: 'nope' })))
    return

  it 'cannot be constructed when a role list contains a non-string.', ->
    (assert (throws -> (new Access { a: [ 1 ] })))
    return

  it 'flattens a deep mask into dotted paths.', ->
    a = (new Access { b: { c: [ 'x' ] } })
    (assert (_.isEqual a.mask, { 'b.c': [ 'x' ] }))
    return

  it 'screens an object down to fields allowed for any of the given roles.', ->
    a = (new Access { a: [ 'x' ], b: [ 'y' ] })
    (assert (_.isEqual (a.screen { a: 1, b: 2 }, [ 'x' ]), { a: 1 }))
    return

  it 'screens to an empty object when no role matches.', ->
    a = (new Access { a: [ 'x' ] })
    (assert (_.isEqual (a.screen { a: 1 }, [ 'z' ]), {}))
    return

  it 'cannot screen a non-object.', ->
    a = (new Access { a: [ 'x' ] })
    (assert (throws -> (a.screen 5, [ 'x' ])))
    return

  it 'cannot screen with a non-array roles argument.', ->
    a = (new Access { a: [ 'x' ] })
    (assert (throws -> (a.screen { a: 1 }, 'x')))
    return

  it 'lists no fields when no role matches.', ->
    a = (new Access { a: [ 'x' ] })
    (assert (_.isEqual (a.fields [ 'z' ]), []))
    return

  it 'cannot list fields with a non-array roles argument.', ->
    a = (new Access { a: [ 'x' ] })
    (assert (throws -> (a.fields 'x')))
    return

