class DoorAgent
  class PusherWorker
    include SuckerPunch::Job

    def perform(message)
      Pusher.trigger('doors', 'state_change', message)
    end
  end
end