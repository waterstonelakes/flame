ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

Adapter    = require '@flame-odm/lib/adapter'
FlameError = require '@flame-odm/lib/flame-error'

_ = require 'lodash'


# The Adapter constructor only classifies its arguments — it never connects to
# Firestore — so this behaviour is unit-testable without credentials.
describe 'Adapter (constructor) --', ->

  it 'has a type of Adapter.', ->
    (assert ((new Adapter()).type == 'Adapter'))
    return

  it 'defaults to the firebase-function cloud when given no service account.', ->
    a = (new Adapter())
    (assert (a.cloud == 'firebase-function'))
    return

  it 'defaults the app name to flame-odm.', ->
    (assert ((new Adapter()).name == 'flame-odm'))
    return

  it 'defaults dbid to (default) and http to true.', ->
    a = (new Adapter())
    (assert (a.dbid == '(default)') && (a.http == true))
    return

  it 'recognizes the firebase-function service account string.', ->
    (assert ((new Adapter 'firebase-function').cloud == 'firebase-function'))
    return

  it 'recognizes the google-cloud service account string.', ->
    (assert ((new Adapter 'google-cloud').cloud == 'google-cloud'))
    return

  it 'recognizes the process-env service account string.', ->
    (assert ((new Adapter 'process-env').cloud == 'process-env'))
    return

  it 'treats any other string as an app name on the firebase-function cloud.', ->
    a = (new Adapter 'my-app')
    (assert (a.cloud == 'firebase-function') && (a.name == 'my-app'))
    return

  it 'treats an object service account as the other cloud and stores it.', ->
    sa = { type: 'service_account', project_id: 'x' }
    a  = (new Adapter sa)
    (assert (a.cloud == 'other') && (_.isEqual a.cfg.sa, sa))
    return

  it 'treats a function service account as the other cloud and stores it.', ->
    fn = -> { type: 'service_account' }
    a  = (new Adapter fn)
    (assert (a.cloud == 'other') && (a.cfg.sa == fn))
    return

  it 'reads dbid and http from the opts argument.', ->
    a = (new Adapter 'process-env', 'app', { dbid: 'db2', http: false })
    (assert (a.dbid == 'db2') && (a.http == false) && (a.name == 'app'))
    return

  it 'throws a FlameError on an invalid service account argument.', ->
    caught = null
    try
      (new Adapter 123)
    catch e
      caught = e
    (assert (caught instanceof FlameError))
    return
