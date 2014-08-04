#= require ./gum

palava = @palava

class palava.Identity
  constructor: (o) ->
    @userMediaConfig = o.userMediaConfig
    @status       = o.status || {}
    @status.name  = o.name

  newUserMedia: ->
    new palava.Gum(@userMediaConfig)

  getName: =>
    @name

  getStatus: =>
    @status
