ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

Access     = require '@flame-odm/lib/access'
Model      = require '@flame-odm/lib/model'
Serializer = require '@flame-odm/lib/serializer'
Validator  = require '@flame-odm/lib/validator'

_ = require 'lodash'


describe 'Model --', ->

  it 'An Model can be created.', ->
    ok = false

    try
      m = (new Model 'Thing', {
        a: 1
        b: 2
      })
      ok = true
    catch m
      _.noop()

    (assert ok)
    return

  it 'An Model be converted into a plain object.', ->
    ok = false

    m = (new Model 'Thing', {
      a: 1
      b: -> 2
      c: { d: (t, d) -> d.a }
      e: (t, d) -> t
    })

    ok = (_.isEqual m.obj(), { a: 1, b: 2, c: { d: 1 }, e: 'Thing' })
    (assert ok)
    return

  it 'An Model can be extended.', ->
    ok = false

    m = (new Model 'Thing', {
      a: 1
      b: -> 2
      c: { d: (t, d) -> d.a }
      e: (t, d) -> t
    })

    m2 = (m.extend 'SubThing', { a: 2, f: 3 })

    ok = (_.isEqual m2.obj(), { a: 2, b: 2, c: { d: 2 }, e: 'SubThing' , f: 3 })
    (assert ok)
    return

  it 'A Record of a Model can be created.', ->
    ok = false

    m = (new Model 'Thing', {
      a: 1
      b: -> 2
      c: { d: (t, d) -> d.a }
      e: (t, d) -> t
    })

    r = (m.create { a: 2 })

    ok = (_.isEqual r.obj(), { a: 2, b: 2, c: { d: 2 }, e: 'Thing'})
    (assert ok)
    return

  throws = (fn) ->
    try
      (fn())
      return false
    catch e
      return true

  Config = require '@flame-odm/lib/config'
  Record = require '@flame-odm/lib/record'

  it 'sets its type to the model type it is given.', ->
    (assert ((new Model 'Thing', { a: 1 }).type == 'Thing'))
    return

  it 'cannot be constructed without a string type.', ->
    (assert (throws -> (new Model 5, { a: 1 })))
    return

  it 'cannot be constructed with an empty type.', ->
    (assert (throws -> (new Model '', { a: 1 })))
    return

  it 'cannot be constructed without a defaults object.', ->
    (assert (throws -> (new Model 'Thing', 5)))
    return

  it 'exposes its defaults as a resolved plain object on data.', ->
    m = (new Model 'Thing', { a: 1, b: -> 2 })
    (assert (_.isEqual m.data, { a: 1, b: 2 }))
    return

  it 'uses the type as the collection by default.', ->
    (assert ((new Model 'Thing', { a: 1 }).collection == 'Thing'))
    return

  it 'derives the collection from a configured collection_field.', ->
    cfg = (new Config { collection_field: 'coll' })
    m   = (new Model 'Thing', { coll: 'widgets', a: 1 }, cfg)
    (assert (m.collection == 'widgets'))
    return

  it 'creates a Record whose values merge over the defaults.', ->
    m = (new Model 'Thing', { a: 1, b: 2 })
    r = (m.create { a: 9 })
    (assert (r instanceof Record) && (_.isEqual r.obj(), { a: 9, b: 2 }))
    return

  it 'lets a create mixin override the model default.', ->
    m = (new Model 'Thing', { a: 1 })
    v = (new Validator { a: (x, o) -> false })
    (assert ((m.create { a: 1 }, v).validator == v))
    return

  it 'creates a fragment with the given id.', ->
    m = (new Model 'Thing', { a: 1 })
    (assert ((m.fragment 'abc', { a: 2 }).id == 'abc'))
    return

  it 'cannot create a fragment without a string id.', ->
    m = (new Model 'Thing', { a: 1 })
    (assert (throws -> (m.fragment 5)))
    return

  it 'lets extend override a mixin and merge defaults.', ->
    m  = (new Model 'Vehicle', { weight: null })
    v  = (new Validator { weight: (x, o) -> false })
    m2 = (m.extend 'Car', { wheels: 4 }, v)
    (assert (m2.validator == v) && (_.isEqual m2.obj(), { weight: null, wheels: 4 }))
    return


