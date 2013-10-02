#!/usr/bin/env ruby
require 'json'
require 'logger'
require 'time'
require 'socket'
require 'singleton'
require 'bundler'
Bundler.require

class DoorAgent

  def initialize(args = {})
    @config = Configuration.instance.merge!(args)

    @logger = Logger.new(STDERR)

    Pusher.app_id     = @config.delete!(:pusher_app_id)
    Pusher.key        = @config.delete!(:pusher_key)
    Pusher.secret     = @config.delete!(:pusher_secret)
    Pusher.encrypted  = true
    Pusher.logger     = @logger

    AWS.config(
      access_key_id:      @config.delete!(:aws_key_id),
      secret_access_key:  @config.delete!(:aws_access_key),
      logger:             @logger
    )

    @config.assert! :s3_bucket
  end
  attr_accessor :config, :logger

  def run
    SerialPort.open(@config.assert!(:serial), 9600, 8, 1, SerialPort::NONE) do |serial_port|
      while string = serial_port.gets
        if message = Message.new_from_string(string)
          logger.ap message
          announce(message)
        else
          logger.error "couldn't parse: #{string}"
        end
      end
    end
  end

  def announce(message)
    case message
    when String
      announce Message.new_from_string(message)
    when Message
      S3Worker.new.async.perform(message)
      PusherWorker.new.async.perform(message)
      true
    end
  end

  class Message < Hash

    STRING_FORMAT = %r{
      ^
      sensor:(?<sensor> \d+)
      \s
      state:(?<state> (open|closed))
      $
    }x

    def self.new_from_string(string)
      if match = STRING_FORMAT.match(string.chomp)
        new.merge( sensor: match[:sensor].to_i, state: match[:state] )
      end
    end

    def initialize
      merge!(
        hostname: Socket.gethostname,
        timestamp: Time.now.utc.iso8601
      )
    end

    def to_jsonp(function_name)
      "#{function_name}(#{to_json})\n"
    end

    def filename
      "#{fetch(:sensor)}.json"
    end

  end

  class S3Worker
    include SuckerPunch::Job

    def perform(message)
      bucket = AWS::S3.new.buckets[::DoorAgent::Configuration.instance.assert!(:s3_bucket)]
      data = message.to_jsonp("setup")
      bucket.objects[message.filename].write(data,
        acl: :public_read,
        content_type: 'application/json',
        content_length: data.length
      )
    end
  end

  class PusherWorker
    include SuckerPunch::Job

    def perform(message)
      Pusher.trigger('doors', 'state_change', message)
    end
  end

  class Configuration < Hash
    include ::Singleton

    def initialize
      env = Hash[%i[
        aws_key_id
        aws_access_key
        s3_bucket
        pusher_app_id
        pusher_key
        pusher_secret
      ].map{ |key| [key, ENV["DOORS_#{key.to_s.upcase}"]] }]

      merge! env
    end

    # Raise an error when deleting a non-existent key.
    def delete!(key)
      assert! key
      delete key
    end

    # Assert that a given key exists or raise an exception.
    def assert!(key)
      if has_key? key
        fetch key
      else
        raise ArgumentError.new("#{key} is required")
      end
    end

  end
end

if __FILE__ == $0
  args = Slop.parse(autocreate: true).to_hash
  DoorAgent.new(args).run
end
