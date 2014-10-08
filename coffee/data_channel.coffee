class palava.DataChannel extends EventEmitter

  MAX_BUFFER: 1024 * 1024

  constructor: (@channel) ->
    @channel.onmessage = (event) => @emit 'message', event.data
    @channel.onclose = () => @emit 'close'
    @channel.onerror = (e) => @emit 'error', e
    @send_buffer = []

  send: (data, cb) ->
    @send_buffer.push([data, cb])

    if @send_buffer.length == 1
      actual_send = () =>
        if @channel.readyState != 'open'
          console.log "Not sending when not open!"
          return

        while @send_buffer.length
          if @channel.bufferedAmount > @MAX_BUFFER
            setTimeout(actual_send, 1)
            return

          [data, cb] = @send_buffer[0]

          try
            @channel.send(data)
          catch e
            setTimeout(actual_send, 1)
            return

          try
            cb?()
          catch e
            # TODO: find a better way to tell the user ...
            console.log 'Exception in write callback:', e

          @send_buffer.shift()

      actual_send()


