ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

Serializer = require '@flame-odm/lib/serializer'

_ = require 'lodash'


describe 'Serializer --', ->

  it 'A Serializer can convert a plain-formatted objects into DB-formatted objects (deep).', ->
    ok = false
    
    s = (new Serializer { prefixes: [ 'a', 'z' ] })
    o = { a: { b: 1, c: 2 }, z: { b_d: 1, c: 2 }}

    db = (s.toDB o)

    ok = (_.isEqual db, { 'a-b': 1, 'a-c': 2, 'z-b-d': 1, 'z-c': 2 })

    (assert ok)
    return

  it 'A Serializer can convert a DB-formatted objects into plain-formatted objects (deep).', ->
    ok = false
    
    s = (new Serializer { prefixes: [ 'a', 'z' ] })
    o = { 'a-b': 1, 'a-c': 2, 'z-b-d': 1, 'z-c': 2 }

    db = (s.fromDB o)

    ok = (_.isEqual db, { a: { b: 1, c: 2 }, z: { b_d: 1, c: 2 }})

    (assert ok)
    return

  it 'A Serializer can convert a plain-formatted objects into DB-formatted objects (flat).', ->
    ok = false
    
    s = (new Serializer())
    o = { a: 1, z_x: 1}

    db = (s.toDB o)

    ok = (_.isEqual db, { a: 1, 'z-x': 1 })

    (assert ok)
    return

  it 'A Serializer can convert a DB-formatted objects into plain-formatted objects (flat).', ->
    ok = false

    s = (new Serializer())
    o = { a: 1, 'z-x': 1 }

    db = (s.fromDB o)

    ok = (_.isEqual db, { a: 1, z_x: 1 })

    (assert ok)
    return

  it 'A Serializer with prefixes fails toDB when a non-prefix top-level field is present.', ->
    s = (new Serializer { prefixes: [ 'a', 'z' ] })
    o = { a: { b: 1 }, id: 'x' }

    ok = ((s.toDB o) == null)

    (assert ok)
    return

  it 'A Serializer with prefixes fails toDB when a prefix value is not an object.', ->
    s = (new Serializer { prefixes: [ 'a' ] })
    o = { a: 'oops' }

    ok = ((s.toDB o) == null)

    (assert ok)
    return

  it 'A Serializer with prefixes fails toDB on an empty object.', ->
    s = (new Serializer { prefixes: [ 'a' ] })

    ok = ((s.toDB {}) == null)

    (assert ok)
    return

  it 'A Serializer with prefixes fails fromDB when a non-prefix key is present.', ->
    s = (new Serializer { prefixes: [ 'a', 'z' ] })
    o = { 'a-b': 1, 'id': 'x' }

    ok = ((s.fromDB o) == null)

    (assert ok)
    return

  it 'A Serializer cannot be constructed with non-string prefixes.', ->
    ok = false

    try
      s = (new Serializer { prefixes: [ 'a', 1 ] })
    catch e
      ok = true

    (assert ok)
    return

  it 'defaults to kebab keys in the db and snake keys in plain objects.', ->
    s = (new Serializer())
    (assert (_.isEqual (s.toDB { my_field: 1 }), { 'my-field': 1 }))
    (assert (_.isEqual (s.fromDB { 'my-field': 1 }), { my_field: 1 }))
    return

  it 'applies a custom camel db field format.', ->
    s = (new Serializer { fmt: { db: { field: 'camel' } } })
    (assert (_.isEqual (s.toDB { my_field: 1 }), { myField: 1 }))
    return

  it 'applies a custom pascal db field format.', ->
    s = (new Serializer { fmt: { db: { field: 'pascal' } } })
    (assert (_.isEqual (s.toDB { my_field: 1 }), { MyField: 1 }))
    return

  it 'normalizes plain keys with the obj field format on the way out.', ->
    s = (new Serializer { fmt: { db: { field: 'camel' } } })
    (assert (_.isEqual (s.fromDB { myField: 1 }), { my_field: 1 }))
    return

  it 'exposes the four case formatters.', ->
    s = (new Serializer())
    (assert ((s.fmt.camel 'a_b') == 'aB'))
    (assert ((s.fmt.kebab 'aB') == 'a-b'))
    (assert ((s.fmt.snake 'aB') == 'a_b'))
    (assert ((s.fmt.pascal 'a_b') == 'AB'))
    return

  it 'uses a custom separator between prefix and subfield in the db.', ->
    s = (new Serializer { prefixes: [ 'a' ], separator: '__' })
    (assert (_.isEqual (s.toDB { a: { b_c: 1 } }), { 'a__b-c': 1 }))
    return

  it 'round-trips a 2-level object through a custom separator.', ->
    s = (new Serializer { prefixes: [ 'a' ], separator: '__' })
    (assert (_.isEqual (s.fromDB { 'a__b-c': 1 }), { a: { b_c: 1 } }))
    return
