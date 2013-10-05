require 'time'
require 'socket'
require 'json'
require 'door_agent/s3_worker'
require 'door_agent/pusher_worker'
require 'door_agent/filesystem_worker'

class DoorAgent
  class Message < Hash

    def initialize(hash)
      merge!(hash)
    end

    def to_jsonp(function_name = 'setup')
      "#{function_name}(#{to_json})\n"
    end

    def filename
        File.join("states", Socket.gethostname, "#{fetch(:door)}.js")
    end

    def announce
      merge! timestamp: Time.now.utc.iso8601
      S3Worker.new.async.perform(self)
      PusherWorker.new.async.perform(self)
      FilesystemWorker.new.async.perform(self)
      true
    end

  end
end