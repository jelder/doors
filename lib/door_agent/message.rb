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

    def filename
        File.join("doors", host, "#{fetch(:id)}.json")
    end

    def host
      Socket.gethostname.split('.').first
    end

    def announce
      merge!(
        timestamp: Time.now.utc.iso8601,
        host: host
      )
      S3Worker.new.async.perform(self)
      PusherWorker.new.async.perform(self)
      FilesystemWorker.new.async.perform(self)
      true
    end

  end
end