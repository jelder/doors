require 'logger'
require 'time'
require 'door_agent/configuration'
require 'door_agent/message'

class DoorAgent

  SERIAL_PROTOCOL = %r{
    ^
    id:(?<id> \d+)
    \s
    state:(?<state> (open|closed))
    $
  }x

  def initialize(args = {})
    @config = Configuration.instance.merge!(args)

    @logger = Logger.new(STDERR)

    Pusher.app_id     = @config.assert!(:pusher_app_id)
    Pusher.key        = @config.assert!(:pusher_key)
    Pusher.secret     = @config.assert!(:pusher_secret)
    Pusher.encrypted  = true
    Pusher.logger     = @logger

    AWS.config(
      access_key_id:      @config.assert!(:aws_key_id),
      secret_access_key:  @config.assert!(:aws_access_key),
      logger:             @logger
    )

    S3Worker.bucket = AWS::S3.new.buckets[@config.assert!(:s3_bucket)]

    @doors = {}
  end
  attr_accessor :config, :logger, :doors

  def run
    SerialPort.open(config.assert!(:serial), 9600, 8, 1, SerialPort::NONE) do |serial_port|
      while string = serial_port.gets
        handle_message(string)
      end
    end
  end

  def handle_message(string)
    if match = SERIAL_PROTOCOL.match(string.chomp)
      door = match[:door].to_i
      message = Message.new(
        door: door,
        state: match[:state]
      )

      if last_change = doors[door]
        message[:last_change] = last_change
      end
      doors[door] = Time.now

      message.announce
    else
      logger.error "couldn't parse: #{string}"
    end
  end

  def demo
    fake_doors = 3.times.map{ |door| {door: door+1, state:0} }
    states = %w[open closed]
    loop do
      door = fake_doors.sample
      door[:state] ^= 1
      handle_message("door:#{door[:door]} state:#{states[door[:state]]}")
      sleep [1,rand(5)].max
    end
  end

end