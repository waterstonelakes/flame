ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

Pager      = require '@flame-odm/lib/pager'
FlameError = require '@flame-odm/lib/flame-error'

_ = require 'lodash'


throws = (fn) ->
  caught = null
  try
    (fn())
  catch e
    caught = e
  return (caught instanceof FlameError)


# Pager.queries builds the underlying Query objects purely (no Firestore), so the
# cursor / order-by / limit / start-at logic that drives paging is unit-testable.
describe 'Pager (constructor) --', ->

  it 'has a type of Pager.', ->
    (assert ((new Pager []).type == 'Pager'))
    return

  it 'defaults the page size to 10.', ->
    (assert ((new Pager []).size == 10))
    return

  it 'uses the size given in opts.', ->
    (assert ((new Pager [], { size: 4 }).size == 4))
    return

  it 'accepts comparison, and/or and order-by constraints.', ->
    q = [ [ 'eq', 'a', 1 ], [ 'and', [ 'gt', 'b', 2 ] ], [ 'order-by', 'a', 'asc' ] ]
    (assert (!(throws -> (new Pager q))))
    return

  it 'rejects limit (a query-only operator).', ->
    (assert (throws -> (new Pager [ [ 'limit', 5 ] ])))
    return

  it 'rejects an unknown constraint.', ->
    (assert (throws -> (new Pager [ [ 'bogus', 'a', 1 ] ])))
    return


describe 'Pager.queries (no cursor) --', ->

  pager = (new Pager [ [ 'order-by', 'letter', 'asc' ] ], { size: 4 })
  qs    = (pager.queries null)

  it 'builds the collection query from the constraints as given.', ->
    (assert (_.isEqual qs.collection.q, [ [ 'order-by', 'letter', 'asc' ] ]))
    return

  it 'reverses the sort direction for the reversed query.', ->
    (assert (_.isEqual qs.reversed.q, [ [ 'order-by', 'letter', 'desc' ] ]))
    return

  it 'limits the items query to size + 1.', ->
    (assert (_.isEqual qs.itemz.q, [ [ 'order-by', 'letter', 'asc' ], [ 'limit', 5 ] ]))
    return

  it 'limits the priors query to 2 and reverses it.', ->
    (assert (_.isEqual qs.priorz.q, [ [ 'order-by', 'letter', 'desc' ], [ 'limit', 2 ] ]))
    return

  it 'leaves the tail query unlimited with no start-at.', ->
    (assert (_.isEqual qs.tail.q, [ [ 'order-by', 'letter', 'asc' ] ]))
    return


describe 'Pager.queries (page-start cursor) --', ->

  pager  = (new Pager [ [ 'order-by', 'letter', 'asc' ] ], { size: 4 })
  cursor = { obj: { letter: 'd' }, position: 'page-start' }
  qs     = (pager.queries cursor)

  it 'injects a start-at built from the order-by field values.', ->
    (assert (_.isEqual qs.itemz.q, [
      [ 'order-by', 'letter', 'asc' ]
      [ 'limit', 5 ]
      [ 'start-at', [ 'd' ] ]
    ]))
    return

  it 'injects the start-at into the priors query too.', ->
    (assert (_.isEqual qs.priorz.q, [
      [ 'order-by', 'letter', 'desc' ]
      [ 'limit', 2 ]
      [ 'start-at', [ 'd' ] ]
    ]))
    return

  it 'injects the start-at into the tail query.', ->
    (assert (_.isEqual qs.tail.q, [ [ 'order-by', 'letter', 'asc' ], [ 'start-at', [ 'd' ] ] ]))
    return

  it 'does not swap collection and reversed for a page-start cursor.', ->
    (assert (_.isEqual qs.collection.q, [ [ 'order-by', 'letter', 'asc' ] ]))
    return


describe 'Pager.queries (page-end cursor) --', ->

  pager  = (new Pager [ [ 'order-by', 'letter', 'asc' ] ], { size: 4 })
  cursor = { obj: { letter: 'd' }, position: 'page-end' }
  qs     = (pager.queries cursor)

  it 'swaps collection and reversed so the collection query walks backward.', ->
    (assert (_.isEqual qs.collection.q, [ [ 'order-by', 'letter', 'desc' ] ]))
    (assert (_.isEqual qs.reversed.q,   [ [ 'order-by', 'letter', 'asc' ] ]))
    return

  it 'limits the (swapped) items query to size + 1 with a start-at.', ->
    (assert (_.isEqual qs.itemz.q, [
      [ 'order-by', 'letter', 'desc' ]
      [ 'limit', 5 ]
      [ 'start-at', [ 'd' ] ]
    ]))
    return


describe 'Pager.queries (reversal) --', ->

  it 'reverses desc to asc.', ->
    qs = ((new Pager [ [ 'order-by', 'letter', 'desc' ] ]).queries null)
    (assert (_.isEqual qs.reversed.q, [ [ 'order-by', 'letter', 'asc' ] ]))
    return

  it 'defaults a two-element order-by to a desc reversal.', ->
    qs = ((new Pager [ [ 'order-by', 'letter' ] ]).queries null)
    (assert (_.isEqual qs.reversed.q, [ [ 'order-by', 'letter', 'desc' ] ]))
    return

  it 'passes non-order-by constraints through the reversal unchanged.', ->
    qs = ((new Pager [ [ 'eq', 'x', 1 ], [ 'order-by', 'letter', 'asc' ] ]).queries null)
    (assert (_.isEqual qs.reversed.q, [ [ 'eq', 'x', 1 ], [ 'order-by', 'letter', 'desc' ] ]))
    return
