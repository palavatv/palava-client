class palava.DataChannel extends EventEmitter

  constructor: (@channel) ->
    @channel.onmessage = (event) => @emit 'message', event.data
    @channel.onclose = () => @emit 'close'
    @send_buffer = []

  send: (data, cb) ->
    @send_buffer.push([data, cb])

    if @send_buffer.length == 1
      actual_send = () =>
        if @channel.readyState != 'open'
          return

        try
          while @send_buffer.length
            [data, cb] = @send_buffer[0]
            @channel.send(data)

            try
              cb?()
            catch e
              # TODO: find a better way to tell the user ...
              console.log 'Exception in write callback', e

            @send_buffer.shift()
        catch
          console.log 'erreur'
          setTimeout(actual_send, 5)

      actual_send()


