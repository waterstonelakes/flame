require('dotenv').config()

ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '/../../')

chai   = require 'chai'
assert = chai.assert

_                  = require 'lodash'
Adapter            = require '@flame-odm/lib/adapter'
Config             = require '@flame-odm/lib/config'
Model              = require '@flame-odm/lib/model'
random             = require '@stablelib/random'
{ all }            = require 'rsvp'
{ hasCredentials } = require '@flame-odm/test-helpers/firestore'


a = (new Adapter 'process-env', 'flame-odm', { http: false })

c = (new Config { id_field: 'id' })

COLLECTION = "e2e_transact_#{(random.randomString 16)}"

Thing = (new Model COLLECTION, {
  id:   -> (random.randomString 20)
  name: null
}, a, c)

created = []


describe 'E2E: Adapter.transact –– (firestore)', ->

  before ->
    (@skip()) unless (hasCredentials())
    return

  after ->
    return unless (hasCredentials())
    await (all (_.map created, ((id) -> (Thing.fragment id).destroy())))
    return

  it 'commits writes made inside the transaction.', ->
    id = (random.randomString 20)
    created.push id
    ok = await (a.transact ((T) ->
      r = (Thing.fragment id, { name: 'tx' })
      await (r.save T)
      return true
    ))
    doc = await (Thing.get id)
    (assert (ok == true) && (doc.name == 'tx'))
    return

  it 'returns the value the callback returns.', ->
    out = await (a.transact ((T) -> return 42))
    (assert (out == 42))
    return

  it 'returns null and rolls back when the callback throws.', ->
    id = (random.randomString 20)
    out = await (a.transact ((T) ->
      r = (Thing.fragment id, { name: 'rollback' })
      await (r.save T)
      throw (new Error 'boom')
    ))
    doc = await (Thing.get id)
    (assert (out == null) && (doc == null))
    return
