first    = require 'lodash/first'
get      = require 'lodash/get'
includes = require 'lodash/includes'


class FirestoreErrors


  type: 'FirestoreErrors'


  CODES:
    0:  'OK'
    1:  'CANCELLED'
    2:  'UNKNOWN'
    3:  'INVALID_ARGUMENT'
    4:  'DEADLINE_EXCEEDED'
    5:  'NOT_FOUND'
    6:  'ALREADY_EXISTS'
    7:  'PERMISSION_DENIED'
    8:  'RESOURCE_EXHAUSTED'
    9:  'FAILED_PRECONDITION'
    10: 'ABORTED'
    11: 'OUT_OF_RANGE'
    12: 'UNIMPLEMENTED'
    13: 'INTERNAL'
    14: 'UNAVAILABLE'
    15: 'DATA_LOSS'
    16: 'UNAUTHENTICATED'


  RETRYABLE: [ 4, 8, 10, 13, 14 ]


  word: (err) ->
    (@.CODES[(get err, 'code')] ? 'UNKNOWN')


  retryable: (err) ->
    (includes @.RETRYABLE, (get err, 'code'))


  index_url: (err) ->
    return null unless (get err, 'code') == 9
    matches = ((get err, 'message', '').match /https:\/\/console\.(?:firebase|cloud)\.google\.com\/\S+/)
    (first matches) ? null


  print: (err, context = {}) ->
    model  = (get context, 'model', '?')
    method = (get context, 'method', '?')
    url    = (@.index_url err)
    line   = "[flame-odm] #{model}.#{method} → #{(@.word err)}"
    line   = "#{line} — create index: #{url}" if url
    (console.error line)
    return


module.exports = FirestoreErrors
