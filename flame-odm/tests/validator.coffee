ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

Validator = require '@flame-odm/lib/validator'

_ = require 'lodash'


describe 'Validator --', ->

  it 'A Validator can be constructed with an object (flat).', ->
    ok = false
    
    vs = { hello: (v, o) -> false }

    try
      v = (new Validator vs)
      ok = true
    catch e
      _.noop()

    (assert ok)
    return

  it 'A Validator can be constructed with an object (deep).', ->
    ok = false
    
    vs = { world: { hello: (v, o) -> false }}

    try
      v = (new Validator vs)
      ok = true
    catch e
      _.noop()

    (assert ok)
    return
  
  it 'A Validator can not be constructed with bad functions (flat).', ->
    ok = false
    
    vs = { hello: (v) -> false }

    try
      v = (new Validator vs)
    catch e
      ok = true

    (assert ok)
    return

  it 'A Validator can not be constructed with bad functions (deep).', ->
    ok = false
    
    vs = { globe: { hello: (v) -> false }}

    try
      v = (new Validator vs)
    catch e
      ok = true

    (assert ok)
    return

  it 'A Validator can be used to validate an object (flat).', ->
    ok = false
    
    vs = { hello: (v, o) -> v == 'world' }

    v = (new Validator vs)
    ok = (v.ok { hello: 'world' })

    (assert ok)
    return

  it 'A Validator can be used to invalidate an object (flat).', ->
    ok = false
    
    vs = { hello: (v, o) -> v == 'world' }

    v = (new Validator vs)
    ok = !(v.ok { hello: 'globe' })

    (assert ok)
    return

  it 'A Validator can be used to validate an object (deep).', ->
    ok = false
    
    vs = { blue: { hello: (v, o) -> v == 'world' }}

    v = (new Validator vs)
    ok = (v.ok { blue: { hello: 'world' }})

    (assert ok)
    return

  it 'A Validator can be used to invalidate an object (deep).', ->
    ok = false
    
    vs = { blue: { hello: (v, o) -> v == 'world' }}

    v = (new Validator vs)
    ok = !(v.ok { blue: { hello: 'globe' }})

    (assert ok)
    return

  it 'A Validator can be used to enumerate invalid values in an object (flat).', ->
    ok = false
    
    vs =
      hello:  (v, o) -> v == 'world'
      hello2: (v, o) -> v == 'world2'

    v = (new Validator vs)
    errors = (v.errors { hello: 'globe', hello2: 'globe' })
    
    ok = (_.isEqual errors, { 'hello': true, 'hello2': true })

    (assert ok)
    return

  it 'A Validator can be used to enumerate invalid values in an object (deep).', ->
    ok = false
    
    vs = { blue: { hello: (v, o) -> v == 'world' }}

    v = (new Validator vs)
    errors = (v.errors { blue: { hello: 'globe' }})
    
    ok = (_.isEqual errors, { 'blue.hello': true })

    (assert ok)
    return

  throws = (fn) ->
    try
      (fn())
      return false
    catch e
      return true

  it 'can be extended with additional validators.', ->
    v  = (new Validator { a: (x, o) -> x == 1 })
    v2 = (v.extend { b: (x, o) -> x == 2 })
    (assert (v2.ok { a: 1, b: 2 }))
    (assert (!(v2.ok { a: 1, b: 9 })))
    return

  it 'validates only the named fields.', ->
    v = (new Validator {
      a: (x, o) -> false
      b: (x, o) -> true
    })
    (assert (v.ok { a: 0, b: 0 }, [ 'b' ]))
    (assert (!(v.ok { a: 0, b: 0 }, [ 'a' ])))
    return

  it 'enumerates errors only for the named fields.', ->
    v = (new Validator {
      a: (x, o) -> false
      b: (x, o) -> false
    })
    (assert (_.isEqual (v.errors { a: 0, b: 0 }, [ 'a' ]), { a: true }))
    return

  it 'reports no errors when everything is valid.', ->
    v = (new Validator { a: (x, o) -> true })
    (assert (_.isEqual (v.errors { a: 1 }), {}))
    return

  it 'cannot validate a field that has no validator function.', ->
    v = (new Validator { a: (x, o) -> true })
    (assert (throws -> (v.ok { a: 1 }, [ 'z' ])))
    return

  it 'cannot enumerate errors for a field that has no validator function.', ->
    v = (new Validator { a: (x, o) -> true })
    (assert (throws -> (v.errors { a: 1 }, [ 'z' ])))
    return
