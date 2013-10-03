require 'time'
require 'socket'
require 'json'
require 'door_agent/s3_worker'
require 'door_agent/pusher_worker'

class DoorAgent
  class Message < Hash

    def initialize(hash)
      merge!(hash)
    end

    def to_jsonp(function_name)
      "#{function_name}(#{to_json})\n"
    end

    def filename
      "#{fetch(:door)}.json"
    end

    def announce
      merge!(
        hostname: Socket.gethostname,
        timestamp: Time.now.utc.iso8601
      )
      return S3Worker.new.async.perform(self), PusherWorker.new.async.perform(self)
    end

  end
end