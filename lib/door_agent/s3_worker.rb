class DoorAgent
  class S3Worker
    include SuckerPunch::Job

    class << self
      attr_accessor :bucket
    end

    def perform(message)
      self.class.bucket.objects[message.filename].write(
        message.to_json,
        acl: :public_read,
        content_type: 'application/json',
        cache_control: 'must-revalidate, proxy-revalidate'
      )
    end
  end
end