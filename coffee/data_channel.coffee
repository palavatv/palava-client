palava = @palava

class palava.DataChannel extends @EventEmitter

  constructor: (@channel) ->
    @channel.onmessage = (event) => @emit 'message', event.data
    @channel.onclose = () => @emit 'close'

  send: (data) -> @channel.send(data)


