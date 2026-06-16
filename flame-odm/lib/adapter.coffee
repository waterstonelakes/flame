FBA_APP         = require 'firebase-admin/app'
FBA_FIRESTORE   = require 'firebase-admin/firestore'
{ getAuth }     = require 'firebase-admin/auth'

FirestoreErrors = require './firestore-errors'
first           = require 'lodash/first'
FlameError      = require './flame-error'
get             = require 'lodash/get'
includes        = require 'lodash/includes'
isArray         = require 'lodash/isArray'
isEmpty         = require 'lodash/isEmpty'
isEqual         = require 'lodash/isEqual'
isFunction      = require 'lodash/isFunction'
isInteger       = require 'lodash/isInteger'
isPlainObject   = require 'lodash/isPlainObject'
isString        = require 'lodash/isString'
last            = require 'lodash/last'
map             = require 'lodash/map'
max             = require 'lodash/max'
min             = require 'lodash/min'
pick            = require 'lodash/pick'
Query           = require './query'
reverse         = require 'lodash/reverse'
set             = require 'lodash/set'
slice           = require 'lodash/slice'
{ all }         = require 'rsvp'


class Adapter


  type: 'Adapter'


  constructor: (sa = null, name = 'flame-odm', opts = {}) ->
    @.cfg  = if (isString sa) then {} else { sa }
    @.name = name
    @.dbid   = (get opts, 'dbid', '(default)')
    @.http   = (get opts, 'http', true)
    @.errors = (get opts, 'errors') ? (new FirestoreErrors())

    @.cloud = switch
      when (isFunction sa)             then 'other'
      when (isPlainObject sa)          then 'other'
      when (sa == 'firebase-function') then 'firebase-function'
      when (sa == 'google-cloud')      then 'google-cloud'
      when (sa == 'process-env')       then 'process-env'
      when (sa == null)                then 'firebase-function'
      when (isString sa)
        @.name = sa
        'firebase-function'
      else
        throw (new FlameError "Invalid arguments passed to `new Adatper()`.")

    return

  connecting: null
  connect: ->
    if @.connecting != null
      await @.connecting
      return

    @.connecting = (do =>
      if !(isEmpty @.fba) && !(isEmpty @.db)
        return

      if @.cloud == 'firebase-function'
        try
          FBA_APP.initializeApp()
          @.fba  = FBA_APP.getApp()
          @.db   = FBA_FIRESTORE.initializeFirestore(@.fba, { preferRest: @.http }, @.dbid)
          @.auth = (getAuth @.fba)
        catch e
          console.log e
          throw (new FlameError "There was an error connecting to Firebase. Ref: 'firebase-function'")
        return


      if @.cloud == 'google-cloud'
        try
          (FBA_APP.initializeApp { credential: FBA_APP.applicationDefault() })
          @.fba  = FBA_APP.getApp()
          @.db   = (FBA_FIRESTORE.initializeFirestore @.fba, { preferRest: @.http }, @.dbid)
          @.auth = (getAuth @.fba)
        catch e
          console.log e
          throw (new FlameError "There was an error connecting to Firebase. Ref: 'google-cloud'")
        return


      if @.cloud == 'process-env'
        try
          sa = (JSON.parse process.env.FB_SERVICE_ACCOUNT)
          (FBA_APP.initializeApp { credential: (FBA_APP.cert sa) }, @.name)
          @.fba  = (FBA_APP.getApp @.name)
          @.db   = (FBA_FIRESTORE.initializeFirestore @.fba, { preferRest: @.http }, @.dbid)
          @.auth = (getAuth @.fba)
        catch e
          console.log e
          throw (new FlameError "There was an error connecting to Firebase. Ref: 'process-env'")
        return


      if @.cloud == 'other'
        try
          sa = @.cfg.sa
          sa = await sa() if (isFunction sa)
          (FBA_APP.initializeApp { credential: (FBA_APP.cert sa) }, @.name)
          @.fba  = (FBA_APP.getApp @.name)
          @.db   = (FBA_FIRESTORE.initializeFirestore @.fba, { preferRest: @.http }, @.dbid)
          @.auth = (getAuth @.fba)
        catch e
          console.log e
          throw (new FlameError "There was an error connecting to Firebase. Ref: 'other'")
        return
    )
    await @.connecting



  count: (model, query) ->
    await @.connect()
    col_ref = (@.db.collection "#{model.collection}")
    fbq = (query.prepare col_ref, model.serializer)
    try
      count = await fbq.count().get()
      if (isInteger count?.data?().count)
        return count.data().count
    catch err
      (@.errors.print err, { model: model.collection, method: 'count' })
    return null


  del: (model, id, transaction = null) ->
    await @.connect()

    deleted_field    = (get model, 'config.opts.deleted_field')
    deleted_at_field = (get model, 'config.opts.deleted_at_field')
    updated_at_field = (get model, 'config.opts.updated_at_field')

    if !deleted_field
      throw (new FlameError "A soft delete requires a `deleted_field` config option.")

    patch = (set {}, deleted_field, true)
    if deleted_at_field
      fn  = (get model.defaults, updated_at_field)
      now = if (isFunction fn) then (fn model.type, model.defaults) else null
      (set patch, deleted_at_field, now)

    data = (model.serializer.toDB patch)
    return false if data == null

    dr = (@.db.doc "#{model.collection}/#{id}")
    if transaction
      await (transaction.update dr, data)
    else
      try
        await (dr.update data)
      catch err
        (@.errors.print err, { model: model.collection, method: 'del' })
        return false
    return true


  destroy: (record, transaction = null) ->
    await @.connect()
    dr = (@.db.doc "#{record.collection}/#{record.id}")
    if transaction
      await (transaction.delete dr)
    else
      try
        await dr.delete()
      catch err
        (@.errors.print err, { model: record.collection, method: 'destroy' })
        return false
    return true


  find: (model, query, fields = null, transaction = null) ->
    await @.connect()
    q = (new Query [ query.q..., [ 'limit', 1 ] ], query.serializer)
    ls = await (@.findAll model, q, fields, transaction)
    return (first ls) ? null


  get: (model, id, fields = null, transaction = null) ->
    await @.connect()
    dr = (@.db.doc "#{model.collection}/#{id}")
    if transaction
      ds = await (transaction.get dr)
      if ds.exists
        obj = (model.serializer.fromDB ds.data())
        return null if obj == null
        return if fields then (pick obj, fields) else obj
      return null
    else
      try
        ds = await dr.get()
        if ds.exists
          obj = (model.serializer.fromDB ds.data())
          return null if obj == null
          return if fields then (pick obj, fields) else obj
      catch err
        (@.errors.print err, { model: model.collection, method: 'get' })
    return null


  getAll: (model, ids, fields = null) ->
    await @.connect()
    drs = (map ids, ((id) => (@.db.doc "#{model.collection}/#{id}")))
    dss = await (@.db.getAll drs...)
    if !(isEmpty dss)
      return (map dss, ((ds) ->
        return null if !ds.exists
        obj = (model.serializer.fromDB ds.data())
        return null if obj == null
        return if fields then (pick obj, fields) else obj
    ))
    return null


  findAll: (model, query, fields = null, transaction = null) ->
    await @.connect()
    col_ref  = (@.db.collection "#{model.collection}")
    fbq = (query.prepare col_ref, model.serializer)
    if (isArray fields)
      s = model.serializer
      fs = (map fields, (f) -> (s.fmt[s.fmts.field.db] f))
      fbq = (fbq.select fs...)
    if transaction
      qs = await (transaction.get fbq)
      if !qs.empty
        objs = (map qs.docs, ((ds) -> (model.serializer.fromDB ds.data())))
        return null if (includes objs, null)
        return objs
      return null
    else
      try
        qs = await fbq.get()
        if !qs.empty
          objs = (map qs.docs, ((ds) -> (model.serializer.fromDB ds.data())))
          return null if (includes objs, null)
          return objs
      catch err
        (@.errors.print err, { model: model.collection, method: 'findAll' })
      return null


  page: (model, pager = null, cursor = null, fields = null, transaction = null, counts = true) ->
    CPEND = (get cursor, 'position') == 'page-end'

    await @.connect()
    queries = (pager.queries cursor)
    [ coll_first, coll_last, itemz, priorz, total, tail_count ] = await (all [
      (@.find    model, queries.collection, fields, transaction)
      (@.find    model, queries.reversed,   fields, transaction)
      (@.findAll model, queries.itemz,      fields, transaction)
      (@.findAll model, queries.priorz,     fields, transaction)
      (if counts then (@.count model, queries.collection) else 0)
      (if counts then (@.count model, queries.tail) else 0)
    ])

    pg_count = (min [ pager.size, (get itemz, 'length', 0) ])
    items    = (slice itemz, 0, pg_count)

    if CPEND
      items = (reverse items)
      [ coll_first, coll_last ] = [ coll_last, coll_first ]

    at_start = (isEqual coll_first, (first items)) || (isEmpty items)
    at_end   = (isEqual coll_last, (last items)) || (isEmpty items)

    previous = ({ obj: priorz[1], position: 'page-end' } if !at_start) ? null
    next     = ({ obj: itemz[pg_count], position: 'page-start' } if !at_end) ? null

    after  = tail_count - pg_count
    before = (total - tail_count)

    if CPEND
      [ after, before ] = [ before, after ]
      previous = ({ obj: itemz[pg_count], position: 'page-end' } if !at_start) ? null
      next     = ({ obj: priorz[1], position: 'page-start' } if !at_end) ? null

    return {
      counts:
        total:    if counts then total    else null
        before:   if counts then before   else null
        page:     if counts then pg_count else null
        after:    if counts then after    else null
      collection:
        first:    coll_first
        last:     coll_last
      page:
        first:    (first items)
        items:    items
        last:     (last items)
      cursors:
        previous: previous
        current:  cursor
        next:     next
    }


  save: (record, transaction = null) ->
    await @.connect()
    data = (record.serializer.toDB record.data)
    return false if data == null
    dr = (@.db.doc "#{record.collection}/#{record.id}")
    if transaction
      await (transaction.create dr, data)
    else
      try
        await (dr.create data)
      catch err
        (@.errors.print err, { model: record.collection, method: 'save' })
        return false
    return true


  transact: (fn) ->
    await @.connect()
    try
      return await (@.db.runTransaction ((t) -> await (fn t)))
    catch err
      (@.errors.print err, { method: 'transact' })
      return null


  traverse: (model, pager, fn, fields = null) ->
    cursor = null
    pg     = null

    while (!pg || cursor)
      pg     = await (@.page model, pager, cursor, fields, null, false)
      items  = (get pg, 'page.items', [])
      cursor = (get pg, 'cursors.next')
      await (all (map items, ((r) -> await (fn r))))

    return


  update: (record, fields = [], transaction = null) ->
    await @.connect()
    data = (record.serializer.toDB (pick record.data, fields))
    return false if data == null
    dr = (@.db.doc "#{record.collection}/#{record.id}")
    if transaction
      await (transaction.update dr, data)
    else
      try
        await (dr.update data)
      catch err
        (@.errors.print err, { model: record.collection, method: 'update' })
        return false
    return true




module.exports = Adapter
