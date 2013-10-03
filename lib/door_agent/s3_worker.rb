class DoorAgent
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
end