ma = require 'module-alias'
(ma.addAlias '@flame-odm', __dirname + '../../')

chai   = require 'chai'
assert = chai.assert

FlameError = require '@flame-odm/lib/flame-error'


describe 'FlameError --', ->

  it 'is an instance of Error.', ->
    e = (new FlameError 'boom')
    (assert (e instanceof Error))
    return

  it 'has a name of FlameError.', ->
    e = (new FlameError 'boom')
    (assert (e.name == 'FlameError'))
    return

  it 'preserves the message it is given.', ->
    e = (new FlameError 'something went wrong')
    (assert (e.message == 'something went wrong'))
    return

  it 'can be caught as an Error.', ->
    caught = null
    try
      throw (new FlameError 'nope')
    catch err
      caught = err
    (assert (caught.name == 'FlameError') && (caught.message == 'nope'))
    return
