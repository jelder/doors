require 'logger'
require 'time'
require 'door_agent/configuration'
require 'door_agent/message'
require 'digiusb'

class DoorAgent

  SERIAL_PROTOCOL = %r{
    ^
    sensor:(?<sensor> \d+)
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
    spark = DigiUSB.sparks.last
    while string = spark.gets
      handle_message(string)
    end
  end

  def handle_message(string)
    if match = SERIAL_PROTOCOL.match(string.chomp)
      Message.new(
        sensor: match[:sensor].to_i,
        state: match[:state]
      ).announce
    else
      logger.error "couldn't parse: #{string}"
    end
  end

  def demo(delay = 1)
    fake_doors = 3.times.map{ |sensor| {sensor: sensor+1, state:0} }
    states = %w[open closed]
    loop do
      door = fake_doors.sample
      state = states[door[:state] ^= 1]
      handle_message("sensor:#{door[:sensor]} state:#{state}")
      sleep [1,rand(delay)].max
    end
  end

end