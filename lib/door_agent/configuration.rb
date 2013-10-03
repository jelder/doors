require 'singleton'

class DoorAgent
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
        serial
      ].map{ |key| [key, ENV["DOORS_#{key.to_s.upcase}"]] }]

      merge! env
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