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

c = (new Config {
  id_field:         'id'
  updated_at_field: 'updated_at'
})

COLLECTION = "e2e_record_#{(random.randomString 16)}"

User = (new Model COLLECTION, {
  id:         -> (random.randomString 20)
  name:       null
  updated_at: -> (new Date()).toISOString()
}, a, c)

# every record created here is tracked so the suite can clean up after itself
created = []


describe 'E2E: Record –– (firestore)', ->

  @timeout 15000

  before ->
    (@skip()) unless (hasCredentials())
    return

  after ->
    return unless (hasCredentials())
    await (all (_.map created, ((id) -> (User.fragment id).destroy())))
    return

  it 'save persists a record that get reads back.', ->
    r = (User.create { name: 'Ella' })
    created.push r.id
    saved = await r.save()
    doc   = await (User.get r.id)
    (assert (saved == true) && (doc.name == 'Ella') && (doc.id == r.id))
    return

  it 'save returns false when the id already exists.', ->
    r = (User.create { name: 'Dupe' })
    created.push r.id
    await r.save()
    again = (User.fragment r.id, { name: 'Dupe2' })
    saved = await again.save()
    (assert (saved == false))
    return

  it 'update writes the fields it is given.', ->
    r = (User.create { name: 'Bob' })
    created.push r.id
    await r.save()
    patch = (User.fragment r.id, { name: 'Bobby' })
    ok    = await (patch.update [ 'name' ])
    doc   = await (User.get r.id)
    (assert (ok == true) && (doc.name == 'Bobby'))
    return

  it 'update leaves fields it was not given unchanged.', ->
    r = (User.create { name: 'Cy' })
    created.push r.id
    await r.save()
    patch = (User.fragment r.id, { name: 'WRONG' })
    await (patch.update [])
    doc = await (User.get r.id)
    (assert (doc.name == 'Cy'))
    return

  it 'update refreshes a configured updated_at field.', ->
    r = (User.create { name: 'Di' })
    created.push r.id
    await r.save()
    patch = (User.fragment r.id, { name: 'Di2' })
    await (patch.update [ 'name' ])
    doc = await (User.get r.id)
    (assert (_.isString doc.updated_at))
    return

  it 'destroy permanently removes a record.', ->
    r = (User.create { name: 'Zed' })
    await r.save()
    ok  = await r.destroy()
    doc = await (User.get r.id)
    (assert (ok == true) && (doc == null))
    return
