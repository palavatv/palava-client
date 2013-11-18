Distributor = (channel, peerId = null) ->
  on: (event, handler) ->
    channel.on 'message', (msg) ->
      # console.log('got msg', msg)
      if peerId
        # TODO not in sync with protocol page
        #if msg.event == 'from_peer' and msg.sender_id == peerId and event == msg.data.event
        if msg.sender_id == peerId && event == msg.event
          handler(msg)
      else
        # TODO not in sync with protocol page
        #if msg.event != 'from_peer' and event == msg.event
        if !msg.sender_id && event == msg.event
          handler(msg)

  send: (msg) ->
    if peerId
      payload =
        event: 'send_to_peer'
        peer_id: peerId
        data: msg
    else
      payload = msg
    channel.send(payload)

namespace 'palava', (exports) ->
  exports.Distributor = Distributor
