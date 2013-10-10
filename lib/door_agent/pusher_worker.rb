class DoorAgent
  class PusherWorker
    include SuckerPunch::Job

    CHANNEL = 'change_events'

    def perform(message)
      @@logger ||= ::Logger.new(STDERR)
      @@logger.info "Pusher.trigger(#{CHANNEL.inspect}, #{message.label.inspect}, #{message.inspect})"
      Pusher.trigger(CHANNEL, message.label, message)
    end
  end
end