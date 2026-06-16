ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

Access     = require '@flame-odm/lib/access'
Model      = require '@flame-odm/lib/model'
Serializer = require '@flame-odm/lib/serializer'
Validator  = require '@flame-odm/lib/validator'

_ = require 'lodash'


describe 'Record --', ->

  it 'A Record can be validated.', ->
    ok = false

    m = (new Model 'Thing', {
      a: 1
      b: -> 2
    })

    r = (m.create { a: 2 })

    ok = r.ok()
    (assert ok)
    return

  it 'A Record can enumerate errors.', ->
    ok = false

    m = (new Model 'Thing', {
      a: 1
      b: -> 2
    })

    r = (m.create { a: 2 })

    e = r.errors()
    ok = (_.isEqual e, {})
    (assert ok)
    return

  it 'A Record with errors can be validated.', ->
    ok = false

    m = (new Model 'Thing', {
      a: 1
      b: -> 2
    })
    v = (new Validator { a: (v, o) -> false })

    r = (m.create { a: 2 }, v)

    ok = !r.ok()
    (assert ok)
    return

  it 'A Record with errors can enumerate errors.', ->
    ok = false

    m = (new Model 'Thing', {
      a: 1
      b: -> 2
    })
    v = (new Validator { a: (v, o) -> false })

    r = (m.create { a: 2 }, v)

    e = r.errors()

    ok = (_.isEqual e, { a: true })
    (assert ok)
    return

  it 'A Record with errors can be validated by field.', ->
    ok = false

    m = (new Model 'Thing', {
      a: 1
      b: -> 2
    })
    v = (new Validator {
      a: (v, o) -> false
      b: (v, o) -> false
    })

    r = (m.create { a: 2, b: 1 }, v)

    ok = !(r.ok [ 'a' ])
    (assert ok)
    return

  it 'A Record with errors can enumerate errors by field.', ->
    ok = false

    m = (new Model 'Thing', {
      a: 1
      b: -> 2
    })
    v = (new Validator {
      a: (v, o) -> false
      b: (v, o) -> false
    })

    r = (m.create { a: 2, b: 1 }, v)

    e = (r.errors [ 'a' ])

    ok = (_.isEqual e, { a: true })
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

  it 'is an instance of Record.', ->
    m = (new Model 'Thing', { a: 1 })
    (assert ((m.create { a: 1 }) instanceof Record))
    return

  it 'cannot be constructed without a string type.', ->
    (assert (throws -> (new Record 5, null, { a: 1 })))
    return

  it 'cannot be constructed with a non-object values argument.', ->
    (assert (throws -> (new Record 'Thing', null, 5)))
    return

  it 'merges values over defaults in obj().', ->
    m = (new Model 'Thing', { a: 1, b: -> 2 })
    r = (m.create { a: 9 })
    (assert (_.isEqual r.obj(), { a: 9, b: 2 }))
    return

  it 'generates a random 36-character id when none is configured.', ->
    m = (new Model 'Thing', { a: 1 })
    r = (m.create { a: 1 })
    (assert (_.isString r.id) && (r.id.length == 36))
    return

  it 'derives its id from a configured id_field.', ->
    cfg = (new Config { id_field: 'letter' })
    m   = (new Model 'Alphabet', { letter: 'q' }, cfg)
    (assert ((m.create {}).id == 'q'))
    return

  it 'prefers an explicit fragment id over the configured id_field.', ->
    cfg = (new Config { id_field: 'letter' })
    m   = (new Model 'Alphabet', { letter: 'q' }, cfg)
    (assert ((m.fragment 'explicit', {}).id == 'explicit'))
    return

  it 'derives its collection from a configured collection_field.', ->
    cfg = (new Config { collection_field: 'coll' })
    m   = (new Model 'Thing', { coll: 'widgets', a: 1 }, cfg)
    (assert ((m.create {}).collection == 'widgets'))
    return

  it 'is valid when its model has no validator rules.', ->
    m = (new Model 'Thing', { a: 1 })
    (assert ((m.create { a: 1 }).ok()))
    return

  it 'cannot validate a field that has no validator function.', ->
    m = (new Model 'Thing', { a: 1 })
    r = (m.create { a: 1 })
    (assert (throws -> (r.ok [ 'x' ])))
    return

