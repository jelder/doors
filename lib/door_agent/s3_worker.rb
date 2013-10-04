class DoorAgent
  class S3Worker
    include SuckerPunch::Job

    def perform(message)
      bucket = AWS::S3.new.buckets[::DoorAgent::Configuration.instance.assert!(:s3_bucket)]
      data = message.to_jsonp("receive")
      bucket.objects[message.filename].write(data,
        acl: :public_read,
        content_type: 'application/json',
        content_length: data.length
      )
      path = File.expand_path(File.join(File.dirname(__FILE__), "../../public/#{message.filename}"))
      File.open(path, 'w') do |file|
        file.write(data)
      end
    end
  end
end