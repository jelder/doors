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

    @bucket = AWS::S3.new.buckets.create(@options.delete! :s3_bucket)

    @logger = Logger.new(STDERR)
  end
  attr_accessor :options, :logger

  def run
    SerialPort.open(options.delete!(:serial, 9600, 8, 1, SerialPort::NONE)) do |serial_port|
      while string = serial_port.gets.chomp
        if message = parse(string)
          logger.ap message
          announce(message)
        else
          logger.error "couldn't parse: #{string}"
        end
      end
    end
  end

  def parse(string)
    match = string.scan(MESSAGE_FORMAT)
    message = match.hash.slice(*%i[ id state ])
    if match.has_key :id && match.has_key :state
      message.merge(timestamp: Time.now.utc.iso8601)
    else
      false
    end
  end

  def announce(id, state)
    S3Worker.new.async.perform(@options.slice(:s3_bucket).merge(id: id, state: state))
    PusherWorker.new.async.perform(id: id, state: state)
  end

  class S3Worker
    include SuckerPunch::Job
    workers 2

    def perform(options = {})
      bucket = AWS::S3.new.buckets.create(@options.delete! :s3_bucket)
      id = options[:id]
      data = options.slice(*%i[ id state timestamp]).to_jsonp("setup")
      bucket.objects["#{id}.json"].write(data,
        acl: :public,
        content_type: 'application/json',
        content_length: data.length
      )
    end
  end

  class PusherWorker
    include SuckerPunch::Job
    workers 2

    def perform(options = {})
      Pusher.trigger('doors', 'state_change', options.slice(*%i[ id state timestamp ]))
    end
  end

end

class Hash
  def delete!(key)
    if has_key? key
      delete(key)
    else
      raise ArgumentError.new("#{key} is required")
    end
  end
  def to_jsonp(function_name)
    "#{function_name}(#{to_json})"
  end
end

if __FILE__ == $0
  agent = DoorAgent.new( Slop.parse(autocreate: true) ).run
end
