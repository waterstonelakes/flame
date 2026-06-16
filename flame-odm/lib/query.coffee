each        = require 'lodash/each'
every       = require 'lodash/every'
includes    = require 'lodash/includes'
isArray     = require 'lodash/isArray'
join        = require 'lodash/join'
keys        = require 'lodash/keys'
map         = require 'lodash/map'

FlameError  = require './flame-error'
Serializer  = require './serializer'
{ Filter }  = require 'firebase-admin/firestore'


class Query


  type: 'Query'


  # fbq = firestore query, s = serializer, f = field, v(s) = value(s), cl(s) = clause(s)
  filters =
    'eq':                 (s, f, v) -> (Filter.where (s.fmt[s.fmts.field.db] f), '==', v)
    'eq-any':            (s, f, vs) -> (Filter.where (s.fmt[s.fmts.field.db] f), 'in', vs)
    'gt':                 (s, f, v) -> (Filter.where (s.fmt[s.fmts.field.db] f), '>', v)
    'gte':                (s, f, v) -> (Filter.where (s.fmt[s.fmts.field.db] f), '>=', v)
    'includes':           (s, f, v) -> (Filter.where (s.fmt[s.fmts.field.db] f), 'array-contains', v)
    'includes-any':      (s, f, vs) -> (Filter.where (s.fmt[s.fmts.field.db] f), 'array-contains-any', vs)
    'lt':                 (s, f, v) -> (Filter.where (s.fmt[s.fmts.field.db] f), '<', v)
    'lte':                (s, f, v) -> (Filter.where (s.fmt[s.fmts.field.db] f), '<=', v)
    'not-eq':             (s, f, v) -> (Filter.where (s.fmt[s.fmts.field.db] f), '!=', v)
    'not-eq-any':        (s, f, vs) -> (Filter.where (s.fmt[s.fmts.field.db] f), 'not-in', vs)

  ops =
    'and':         (fbq, s, cls...) -> (fbq.where (andClause cls, s))
    'eq':            (fbq, s, f, v) -> (fbq.where (s.fmt[s.fmts.field.db] f), '==', v)
    'eq-any':       (fbq, s, f, vs) -> (fbq.where (s.fmt[s.fmts.field.db] f), 'in', vs)
    'gt':            (fbq, s, f, v) -> (fbq.where (s.fmt[s.fmts.field.db] f), '>', v)
    'gte':           (fbq, s, f, v) -> (fbq.where (s.fmt[s.fmts.field.db] f), '>=', v)
    'includes':      (fbq, s, f, v) -> (fbq.where (s.fmt[s.fmts.field.db] f), 'array-contains', v)
    'includes-any': (fbq, s, f, vs) -> (fbq.where (s.fmt[s.fmts.field.db] f), 'array-contains-any', vs)
    'limit':            (fbq, _, n) -> (fbq.limit n)
    'lt':            (fbq, s, f, v) -> (fbq.where (s.fmt[s.fmts.field.db] f), '<', v)
    'lte':           (fbq, s, f, v) -> (fbq.where (s.fmt[s.fmts.field.db] f), '<=', v)
    'not-eq':        (fbq, s, f, v) -> (fbq.where (s.fmt[s.fmts.field.db] f), '!=', v)
    'not-eq-any':   (fbq, s, f, vs) -> (fbq.where (s.fmt[s.fmts.field.db] f), 'not-in', vs)
    'or':          (fbq, s, cls...) -> (fbq.where (orClause cls, s))
    'order-by':      (fbq, s, f, d) -> (fbq.orderBy (s.fmt[s.fmts.field.db] f), (d ? 'asc'))
    'start-at':        (fbq, _, v)  -> (fbq.startAt v...)


  ALLOWED_OPS     = (keys ops)
  ALLOWED_FILTERS = (keys filters)


  orClause = (cls, serializer) ->
    return (Filter.or ...(map cls, ((cl) -> filters[cl[0]] serializer, ...cl[1..])))


  andClause = (cls, serializer) ->
    return (Filter.and ...(map cls, ((cl) -> filters[cl[0]] serializer, ...cl[1..])))


  constructor: (q = [], serializer = null) ->
    ok = (every q, (statement) ->
      return false if !(isArray statement)
      op = statement[0]
      return false if !(includes ALLOWED_OPS, op)
      return true  if !(includes [ 'and', 'or' ], op)
      return (every statement[1..], (cl) -> (isArray cl) && (includes ALLOWED_FILTERS, cl[0]))
    )

    if !ok
      e = "A Query may only use known operators: #{(join ALLOWED_OPS, ', ')}."
      throw (new FlameError e)
      return

    @.serializer = serializer ? (new Serializer())
    @.q = q
    return


  prepare: (col_ref, serializer = null) ->
    s = serializer ? @.serializer
    fbq = col_ref
    (each @.q, (statement) ->
      fbq = (ops[statement[0]] fbq, s, ...statement[1..])
      return
    )
    return fbq


module.exports = Query
