class DoorAgent
  class FilesystemWorker
    include SuckerPunch::Job

    def perform(message)
      path = File.join(File.expand_path("../../../public", __FILE__), message.filename)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |file|
        file.write(message.to_jsonp)
      end
    end

  end
end