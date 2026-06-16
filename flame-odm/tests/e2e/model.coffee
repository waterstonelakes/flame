require('dotenv').config()

ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '/../../')

chai   = require 'chai'
assert = chai.assert

_                  = require 'lodash'
Adapter            = require '@flame-odm/lib/adapter'
Config             = require '@flame-odm/lib/config'
Model              = require '@flame-odm/lib/model'
Pager              = require '@flame-odm/lib/pager'
Query              = require '@flame-odm/lib/query'
random             = require '@stablelib/random'
{ all }            = require 'rsvp'
{ hasCredentials } = require '@flame-odm/test-helpers/firestore'


a = (new Adapter 'process-env', 'flame-odm', { http: false })

c = (new Config {
  id_field:         'letter'
  deleted_field:    'deleted'
  deleted_at_field: 'deleted_at'
  updated_at_field: 'updated_at'
})

# A unique collection per run keeps the suite self-contained and idempotent: it
# seeds the letters a–z keyed by `letter` and removes them when it is done.
COLLECTION = "e2e_model_#{(random.randomString 16)}"

Alphabet = (new Model COLLECTION, {
  letter:     null
  deleted:    -> false
  deleted_at: -> null
  updated_at: -> (new Date()).toISOString()
}, a, c)

LETTERS = (_.split 'abcdefghijklmnopqrstuvwxyz', '')


describe 'E2E: Model –– (firestore)', ->

  before ->
    (@skip()) unless (hasCredentials())
    return

  before ->
    await (all (_.map LETTERS, ((l) -> (Alphabet.create { letter: l }).save())))
    return

  after ->
    return unless (hasCredentials())
    await (all (_.map LETTERS, ((l) -> (Alphabet.fragment l).destroy())))
    return

  it 'get returns a document by id.', ->
    doc = await (Alphabet.get 'c')
    (assert (doc.letter == 'c'))
    return

  it 'get returns null for a missing id.', ->
    doc = await (Alphabet.get 'not-a-real-id')
    (assert (doc == null))
    return

  it 'get can project a subset of fields.', ->
    doc = await (Alphabet.get 'c', [ 'letter' ])
    (assert (_.isEqual (_.keys doc), [ 'letter' ]))
    return

  it 'getAll returns documents for the given ids, in order.', ->
    docs = await (Alphabet.getAll [ 'a', 'b', 'c' ])
    (assert (_.isEqual (_.map docs, 'letter'), [ 'a', 'b', 'c' ]))
    return

  it 'getAll returns a null entry for a missing id.', ->
    docs = await (Alphabet.getAll [ 'a', 'not-real', 'c' ])
    (assert (docs[0].letter == 'a') && (docs[1] == null) && (docs[2].letter == 'c'))
    return

  it 'find returns the first matching document.', ->
    q   = (new Query [ [ 'gt', 'letter', 'b' ], [ 'order-by', 'letter', 'asc' ] ])
    doc = await (Alphabet.find q)
    (assert (doc.letter == 'c'))
    return

  it 'find returns null when nothing matches.', ->
    doc = await (Alphabet.find (new Query [ [ 'eq', 'letter', 'zz' ] ]))
    (assert (doc == null))
    return

  it 'findAll returns every matching document.', ->
    q    = (new Query [ [ 'eq-any', 'letter', [ 'a', 'e', 'i' ] ], [ 'order-by', 'letter', 'asc' ] ])
    docs = await (Alphabet.findAll q)
    (assert (_.isEqual (_.map docs, 'letter'), [ 'a', 'e', 'i' ]))
    return

  it 'findAll can project a subset of fields.', ->
    q    = (new Query [ [ 'eq', 'letter', 'a' ] ])
    docs = await (Alphabet.findAll q, [ 'letter' ])
    (assert (_.isEqual (_.keys docs[0]), [ 'letter' ]))
    return

  it 'findAll returns null when nothing matches.', ->
    docs = await (Alphabet.findAll (new Query [ [ 'eq', 'letter', 'zz' ] ]))
    (assert (docs == null))
    return

  it 'count counts the documents that satisfy a query.', ->
    q = (new Query [ [ 'gt', 'letter', 'b' ], [ 'lte', 'letter', 'f' ] ])
    n = await (Alphabet.count q)
    (assert (n == 4))
    return

  it 'count with an empty query counts the whole collection.', ->
    n = await (Alphabet.count (new Query []))
    (assert (n == 26))
    return

  it 'traverse visits every matching record exactly once.', ->
    seen  = []
    pager = (new Pager [ [ 'order-by', 'letter', 'asc' ] ], { size: 5 })
    await (Alphabet.traverse pager, ((r) ->
      seen.push r.letter
      return
    ))
    (assert (_.isEqual (_.sortBy seen), LETTERS))
    return

  it 'del soft-deletes a document, leaving it readable.', ->
    ok  = await (Alphabet.del 'a')
    doc = await (Alphabet.get 'a')
    (assert (ok == true) && (doc.deleted == true) && (doc.deleted_at != null))
    return
