#= require ./gum

class Identity
  constructor: (o) ->
    @userMediaConfig = o.userMediaConfig
    @name            = o.name

  newUserMedia: ->
    new palava.Gum(@userMediaConfig)

  getName: ->
    @name

namespace 'palava', (exports) ->
  exports.Identity = Identity