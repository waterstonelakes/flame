camelCase     = require 'lodash/camelCase'
every         = require 'lodash/every'
get           = require 'lodash/get'
identity      = require 'lodash/identity'
includes      = require 'lodash/includes'
isArray       = require 'lodash/isArray'
isEmpty       = require 'lodash/isEmpty'
isFunction    = require 'lodash/isFunction'
isPlainObject = require 'lodash/isPlainObject'
isString      = require 'lodash/isString'
kebabCase     = require 'lodash/kebabCase'
keys          = require 'lodash/keys'
mapKeys       = require 'lodash/mapKeys'
replace       = require 'lodash/replace'
set           = require 'lodash/set'
snakeCase     = require 'lodash/snakeCase'
split         = require 'lodash/split'
upperFirst    = require 'lodash/upperFirst'

FlameError    = require './flame-error'


class Serializer


  type: 'Serializer'


  constructor: (opts = {}) ->
    if (opts.prefixes?) && (!(isArray opts.prefixes) || !(every opts.prefixes, isString))
      e = "A Serializer's `prefixes` option must be an array of strings."
      throw (new FlameError e)
      return

    @.prefixes  = if (isArray opts.prefixes)   then opts.prefixes  else null
    @.separator = if (isString opts.separator) then opts.separator else '-'
    @.fmts =
      field:
        db:    (get opts, 'fmt.db.field')  ? 'kebab'
        plain: (get opts, 'fmt.obj.field') ? 'snake'
    return


  fmt:
    camel:  (s) -> (camelCase s)
    kebab:  (s) -> (kebabCase s)
    pascal: (s) -> (upperFirst (camelCase s))
    snake:  (s) -> (snakeCase s)


  fromDB: (obj) ->
    if !(isEmpty @.prefixes)
      valid = !(isEmpty obj) && (every (keys obj), ((k) => (includes @.prefixes, (split k, @.separator, 1)[0])))
      return null if !valid

    o = {}
    for k in (keys obj)
      prefix = (split k, @.separator, 1)[0]
      tail   = (replace k, "#{prefix}#{@.separator}", '')
      if (includes @.prefixes, prefix)
        p_fmt = (@.fmt[@.fmts.field.plain] prefix)
        t_fmt = (@.fmt[@.fmts.field.plain] tail)
        (set o, "#{p_fmt}.#{t_fmt}", obj[k])
      else
        o[(@.fmt[@.fmts.field.plain] k)] = obj[k]
    return o


  toDB: (obj) ->
    if (isEmpty @.prefixes)
      return (mapKeys obj, (v, k) => (@.fmt[@.fmts.field.db] k))

    valid = !(isEmpty obj) && (every (keys obj), ((k) => (includes @.prefixes, k) && (isPlainObject obj[k])))
    return null if !valid

    o = {}
    for k in (keys obj)
      p_fmt = (@.fmt[@.fmts.field.db] k)
      for sk in (keys obj[k])
        sk_fmt = (@.fmt[@.fmts.field.db] sk)
        o["#{p_fmt}#{@.separator}#{sk_fmt}"] = obj[k][sk]
    return o



module.exports = Serializer
