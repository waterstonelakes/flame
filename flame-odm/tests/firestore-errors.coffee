ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

FirestoreErrors = require '@flame-odm/lib/firestore-errors'


# captures whatever `fn` writes to console.error, restoring it afterwards.
capture = (fn) ->
  out  = []
  orig = console.error
  console.error = (args...) -> out.push (args.join ' ')
  try
    (fn())
  finally
    console.error = orig
  return out


# FirestoreErrors is pure logic over an error's gRPC `code` (plus a console
# write in `print`), so it is unit-testable without Firestore or credentials.
describe 'FirestoreErrors --', ->

  fe = (new FirestoreErrors())


  it 'has a type of FirestoreErrors.', ->
    (assert (fe.type == 'FirestoreErrors'))
    return

  it 'word maps a numeric code to its canonical name.', ->
    (assert (fe.word { code: 0 }) == 'OK')
    (assert (fe.word { code: 6 }) == 'ALREADY_EXISTS')
    (assert (fe.word { code: 9 }) == 'FAILED_PRECONDITION')
    (assert (fe.word { code: 11 }) == 'OUT_OF_RANGE')
    (assert (fe.word { code: 16 }) == 'UNAUTHENTICATED')
    return

  it 'word returns UNKNOWN for an unmapped or missing code.', ->
    (assert (fe.word { code: 999 }) == 'UNKNOWN')
    (assert (fe.word {}) == 'UNKNOWN')
    (assert (fe.word null) == 'UNKNOWN')
    return

  it 'retryable is true for transient codes.', ->
    (assert (fe.retryable { code: 4 }) == true)
    (assert (fe.retryable { code: 14 }) == true)
    return

  it 'retryable is false for non-transient codes.', ->
    (assert (fe.retryable { code: 6 }) == false)
    (assert (fe.retryable {}) == false)
    return

  it 'index_url extracts the firebase console url from a FAILED_PRECONDITION error.', ->
    url = 'https://console.firebase.google.com/v1/r/project/p/firestore/indexes?create_composite=abc'
    err = { code: 9, message: "The query requires an index. You can create it here: #{url}" }
    (assert (fe.index_url err) == url)
    return

  it 'index_url extracts a cloud console url too.', ->
    url = 'https://console.cloud.google.com/datastore/indexes?create=1'
    (assert (fe.index_url { code: 9, message: "needs index: #{url}" }) == url)
    return

  it 'index_url returns null for a FAILED_PRECONDITION with no url.', ->
    (assert (fe.index_url { code: 9, message: 'precondition failed' }) == null)
    return

  it 'index_url extracts the url regardless of grpc code (firestore tags missing-index as INVALID_ARGUMENT too).', ->
    url = 'https://console.firebase.google.com/v1/r/project/p/firestore/indexes?create_composite=q'
    err = { code: 3, message: "The query requires an index. You can create it here: #{url}" }
    (assert (fe.index_url err) == url)
    return

  it 'index_url returns null when there is no url in the message.', ->
    (assert (fe.index_url { code: 3, message: 'invalid argument' }) == null)
    return

  it 'print writes a single compact model.method → WORD line.', ->
    out = (capture -> (fe.print { code: 6 }, { model: 'users', method: 'save' }))
    (assert (out.length == 1))
    (assert (out[0] == '[flame-odm] users.save → ALREADY_EXISTS'))
    return

  it 'print relabels an index error MISSING_INDEX and appends the create-index url.', ->
    url = 'https://console.firebase.google.com/v1/r/project/p/firestore/indexes?create_composite=z'
    err = { code: 3, message: "create it here: #{url}" }
    out = (capture -> (fe.print err, { model: 'posts', method: 'findAll' }))
    (assert (out[0] == "[flame-odm] posts.findAll → MISSING_INDEX — create index: #{url}"))
    return

  it 'print falls back to ? for missing context.', ->
    out = (capture -> (fe.print { code: 7 }))
    (assert (out[0] == '[flame-odm] ?.? → PERMISSION_DENIED'))
    return
