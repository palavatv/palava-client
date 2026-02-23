import { Gum } from './gum.js'

export class Identity
  constructor: (o) ->
    @userMediaConfig = o.userMediaConfig
    @status       = o.status || {}
    @status.name  = o.name

  newUserMedia: ->
    new Gum(@userMediaConfig)

  getName: =>
    @name

  getStatus: =>
    @status
