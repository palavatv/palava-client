#= require ./gum

palava = @palava

class palava.Identity
  constructor: (o) ->
    @userMediaConfig = o.userMediaConfig
    @name            = o.name

  newUserMedia: ->
    new palava.Gum(@userMediaConfig)

  getName: ->
    @name
