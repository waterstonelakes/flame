ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

Query      = require '@flame-odm/lib/query'
Serializer = require '@flame-odm/lib/serializer'
FlameError = require '@flame-odm/lib/flame-error'

_ = require 'lodash'


throws = (fn) ->
  caught = null
  try
    (fn())
  catch e
    caught = e
  return (caught instanceof FlameError)


describe 'Query (constructor) --', ->

  it 'has a type of Query.', ->
    (assert ((new Query []).type == 'Query'))
    return

  it 'preserves the constraint array it is given.', ->
    q = [ [ 'eq', 'letter', 'a' ] ]
    (assert (_.isEqual (new Query q).q, q))
    return

  it 'defaults to a new Serializer when none is given.', ->
    (assert ((new Query []).serializer.type == 'Serializer'))
    return

  it 'uses the serializer it is given.', ->
    s = (new Serializer())
    (assert ((new Query [], s).serializer == s))
    return

  it 'accepts the comparison operators.', ->
    q = [
      [ 'eq',           'a', 1 ]
      [ 'eq-any',       'b', [ 1, 2 ] ]
      [ 'gt',           'c', 1 ]
      [ 'gte',          'd', 1 ]
      [ 'includes',     'e', 1 ]
      [ 'includes-any', 'f', [ 1 ] ]
      [ 'lt',           'g', 1 ]
      [ 'lte',          'h', 1 ]
      [ 'not-eq',       'i', 1 ]
      [ 'not-eq-any',   'j', [ 1 ] ]
    ]
    (assert (!(throws -> (new Query q))))
    return

  it 'accepts limit, order-by and start-at.', ->
    q = [
      [ 'order-by', 'letter', 'asc' ]
      [ 'limit', 5 ]
      [ 'start-at', [ 'a' ] ]
    ]
    (assert (!(throws -> (new Query q))))
    return

  it 'accepts and / or wrapping leaf comparison filters.', ->
    q = [ [ 'and', [ 'eq', 'a', 1 ], [ 'gt', 'b', 2 ] ], [ 'or', [ 'eq', 'c', 3 ] ] ]
    (assert (!(throws -> (new Query q))))
    return

  it 'rejects an unknown operator.', ->
    (assert (throws -> (new Query [ [ 'bogus', 'a', 1 ] ])))
    return

  it 'rejects a statement that is not an array.', ->
    (assert (throws -> (new Query [ 'eq' ])))
    return

  it 'rejects and / or nested inside and / or.', ->
    (assert (throws -> (new Query [ [ 'and', [ 'and', [ 'eq', 'a', 1 ] ] ] ])))
    return

  it 'rejects a non-filter operator nested inside and / or.', ->
    (assert (throws -> (new Query [ [ 'or', [ 'bogus', 'a', 1 ] ] ])))
    return

  it 'rejects a non-array clause nested inside and / or.', ->
    (assert (throws -> (new Query [ [ 'and', 'eq' ] ])))
    return
