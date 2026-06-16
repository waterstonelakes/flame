ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

Config = require '@flame-odm/lib/config'

_ = require 'lodash'


describe 'Config --', ->

  it 'has a type of Config.', ->
    c = (new Config {})
    (assert (c.type == 'Config'))
    return

  it 'stores the options object it is given verbatim.', ->
    opts = { id_field: 'id', collection_field: 'collection' }
    c    = (new Config opts)
    (assert (_.isEqual c.opts, opts))
    return

  it 'exposes individual options via opts.', ->
    c = (new Config { deleted_field: 'deleted' })
    (assert (c.opts.deleted_field == 'deleted'))
    return
