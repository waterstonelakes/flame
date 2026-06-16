require('dotenv').config()

ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '/../../')

chai   = require 'chai'
assert = chai.assert

_                  = require 'lodash'
Adapter            = require '@flame-odm/lib/adapter'
Config             = require '@flame-odm/lib/config'
FirestoreErrors    = require '@flame-odm/lib/firestore-errors'
Model              = require '@flame-odm/lib/model'
Query              = require '@flame-odm/lib/query'
random             = require '@stablelib/random'
{ all }            = require 'rsvp'
{ hasCredentials } = require '@flame-odm/test-helpers/firestore'


# A handler that records each invocation instead of writing to the console, so a
# test can assert which canonical error a real Firestore call produced. Doubles
# as a demonstration that the handler is a pluggable, overridable mixin.
class Recorder extends FirestoreErrors
  constructor: ->
    super()
    @.calls = []
    return
  print: (err, context = {}) ->
    @.calls.push {
      word:   (@.word err)
      model:  (context.model ? null)
      method: (context.method ? null)
      url:    (@.index_url err)
    }
    return
  reset: ->
    @.calls = []
    return


rec = (new Recorder())

a = (new Adapter 'process-env', 'flame-odm', { http: false, errors: rec })

c = (new Config {
  id_field:         'id'
  updated_at_field: 'updated_at'
})

COLLECTION = "e2e_errors_#{(random.randomString 16)}"

User = (new Model COLLECTION, {
  id:         -> (random.randomString 20)
  name:       null
  rank:       null
  updated_at: -> (new Date()).toISOString()
}, a, c)

created = []


describe 'E2E: FirestoreErrors –– (firestore)', ->

  @timeout 15000

  before ->
    (@skip()) unless (hasCredentials())
    return

  before ->
    await (all (_.map [ 1, 2, 3 ], ((n) ->
      r = (User.create { name: "n#{n}", rank: n })
      created.push r.id
      (r.save())
    )))
    return

  beforeEach ->
    (rec.reset())
    return

  after ->
    return unless (hasCredentials())
    await (all (_.map created, ((id) -> (User.fragment id).destroy())))
    return

  it 'create of a duplicate id reports ALREADY_EXISTS via the handler.', ->
    r = (User.create { name: 'Dupe' })
    created.push r.id
    (assert (await r.save()) == true)
    again = (User.fragment r.id, { name: 'Dupe2' })
    (assert (await again.save()) == false)
    (assert (rec.calls.length == 1))
    [ call ] = rec.calls
    (assert (call.word == 'ALREADY_EXISTS') && (call.method == 'save'))
    (assert (call.model == COLLECTION) && (call.url == null))
    return

  it 'update of a missing id reports NOT_FOUND via the handler.', ->
    ghost = (User.fragment (random.randomString 20), { name: 'Ghost' })
    (assert (await (ghost.update [ 'name' ])) == false)
    (assert (rec.calls.length == 1))
    [ call ] = rec.calls
    (assert (call.word == 'NOT_FOUND') && (call.method == 'update') && (call.model == COLLECTION))
    return

  it 'a query needing a composite index reports FAILED_PRECONDITION with a create-index url.', ->
    # a range filter on `rank` with an order-by on a different field (`name`)
    # forces a composite index a fresh random collection does not have.
    q   = (new Query [ [ 'gt', 'rank', 0 ], [ 'order-by', 'name', 'asc' ] ])
    res = await (User.findAll q)
    (assert (res == null))
    (assert (rec.calls.length == 1))
    [ call ] = rec.calls
    (assert (call.word == 'FAILED_PRECONDITION') && (call.method == 'findAll'))
    (assert (_.startsWith call.url, 'https://'))
    return
