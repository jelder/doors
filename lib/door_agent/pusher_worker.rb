class DoorAgent
  class PusherWorker
    include SuckerPunch::Job

    CHANNEL = 'doors'
    EVENT = 'state_change'

    def perform(message)
      @@logger ||= ::Logger.new(STDERR)
      @@logger.info "Pusher.trigger(#{CHANNEL.inspect}, #{EVENT.inspect}, #{message.inspect})"
      Pusher.trigger(CHANNEL, EVENT, message)
    end
  end
end