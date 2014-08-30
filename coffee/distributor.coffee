palava = @palava

# Distributor supports exchanging direct messages with peers through a channel.
# The incoming messages are filtered and outgoing messages are are sent within
# appropriate `send_to_peer` messages.
#
class palava.Distributor

  # @param channel [palava.Channel] The channel to connect through
  # @param peerId [String] The id of the peer to connect to or `null` for global messages
  #
  constructor: (channel, peerId = null) ->
    @channel = channel
    @peerId = peerId

  # Adds a handler to the Distributor
  #
  # @example
  #   distributor.on 'peer_left', (msg) => console.log "peer left!"
  #
  # @param event [String] Event id on which the handler is called
  # @param handler [function] This function is called when the event is received
  #
  on: (event, handler) =>
    @channel.on 'message', (msg) =>
      # console.log('got msg', msg)
      if @peerId
        # TODO not in sync with protocol page
        #if msg.event == 'from_peer' and msg.sender_id == @peerId and event == msg.data.event
        if msg.sender_id == @peerId && event == msg.event
          handler(msg)
      else
        # TODO not in sync with protocol page
        #if msg.event != 'from_peer' and event == msg.event
        if !msg.sender_id && event == msg.event
          handler(msg)

  # Sends a message through the Distributor
  #
  # @param msg [Object] The message to send through the distributor
  #
  send: (msg) =>
    if @peerId
      payload =
        event: 'send_to_peer'
        peer_id: @peerId
        data: msg
    else
      payload = msg
    @channel.send(payload)
