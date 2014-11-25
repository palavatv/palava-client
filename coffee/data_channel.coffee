palava = @palava

class palava.DataChannel extends @EventEmitter

  MAX_BUFFER: 1024 * 1024

  constructor: (@channel) ->
    @channel.onmessage = (event) => @emit 'message', event.data
    @channel.onclose = () => @emit 'close'
    @channel.onerror = (e) => @emit 'error', e
    @sendBuffer = []

  send: (data, cb) ->
    @sendBuffer.push [data, cb]

    if @sendBuffer.length == 1
      @actualSend()

  actualSend: ->
    if @channel.readyState != 'open'
      console.log "Not sending when not open!"
      return

    while @sendBuffer.length
      if @channel.bufferedAmount > @MAX_BUFFER
        setTimeout(@actualSend.bind(@), 1)
        return

      [data, cb] = @sendBuffer[0]

      try
        @channel.send(data)
      catch e
        setTimeout(@actualSend.bind(@), 1)
        return

      try
        cb?()
      catch e
        # TODO: find a better way to tell the user ...
        console.log 'Exception in write callback:', e

      @sendBuffer.shift()

