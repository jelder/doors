#!/usr/bin/env ruby
require 'json'
require 'logger'
require 'time'
require 'bundler'
Bundler.require

class DoorAgent

  DEFAULTS = {
    aws_region: 'us-east-1'
  }

  MESSAGE_FORMAT = %r{
    door:(?<id> \w+)
    \s+
    state:(?<id> \w+)
  }x

  def initialize(args = {})
    env = Hash[%i[
      aws_key_id
      aws_access_key
      s3_bucket
      pusher_app_id
      pusher_key
      pusher_secret
    ].map{ |key| [key, ENV["DOORS_#{key.to_s.upcase}"]] }]

    @options = DEFAULTS.merge(env).merge(args.to_hash)

    Pusher.app_id     = @options.delete! :pusher_app_id
    Pusher.key        = @options.delete! :pusher_key
    Pusher.secret     = @options.delete! :pusher_secret
    Pusher.encrypted  = true

    AWS.config(
      access_key_id:      @options.delete!(:aws_key_id),
      secret_access_key:  @options.delete!(:aws_access_key),
      region:             @options.delete!(:aws_region)
    )

    setup_bucket

    @logger = Logger.new(STDERR)
  end
  attr_accessor :options, :logger, :bucket

  def setup_bucket
    @bucket = AWS::S3.new.buckets.create(@options.assert! :s3_bucket)
    # ap @bucket
    # @bucket.configure_website
  end

  def run
    SerialPort.open(options.delete!(:serial, 9600, 8, 1, SerialPort::NONE)) do |serial_port|
      while string = serial_port.gets.chomp
        if message = message_from_string(string)
          logger.ap message
          announce(message)
        else
          logger.error "couldn't parse: #{string}"
        end
      end
    end
  end

  def message_from_string(string)
    match = string.scan(MESSAGE_FORMAT)
    message = match.hash.slice(*%i[ id state ])
    if match.has_key(:id) && match.has_key(:state)
      return message
    else
      return false
    end
  end

  def announce(message)
    message.merge! timestamp: Time.now.utc.iso8601
    S3Worker.new.async.perform(@options.slice(:s3_bucket).merge(message))
    PusherWorker.new.async.perform(message)
  end

  class S3Worker
    include SuckerPunch::Job

    def perform(message = {})
      bucket = AWS::S3.new.buckets[message[:s3_bucket]]
      data = message.slice(*%i[ id state timestamp ]).to_jsonp("setup")
      bucket.objects["#{message[:id]}.json"].write(data,
        acl: :public_read,
        content_type: 'application/json',
        content_length: data.length
      )
    end
  end

  class PusherWorker
    include SuckerPunch::Job

    def perform(message = {})
      Pusher.trigger('doors', 'state_change', message.slice(*%i[ id state timestamp ]))
    end
  end

end

class Hash

  # Raise an error when deleting a non-existent key.
  def delete!(key)
    assert! key
    delete key
  end

  # Assert that a given key exists or raise an exception.
  def assert!(key)
    if has_key? key
      fetch(key)
    else
      raise ArgumentError.new("#{key} is required")
    end
  end

  # Render as JSON passed as argument to named function.
  def to_jsonp(function_name)
    "#{function_name}(#{to_json})\n"
  end

  # From https://github.com/rails/rails/blob/2ef4d5ed5cbbb2a9266c99535e5f51918ae3e3b6/activesupport/lib/active_support/core_ext/hash/slice.rb#L15-L18
  def slice(*keys)
    keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
    keys.each_with_object(self.class.new) { |k, hash| hash[k] = self[k] if has_key?(k) }
  end

end

if __FILE__ == $0
  args = Slop.parse(autocreate: true)
  DoorAgent.new(args).run
end
