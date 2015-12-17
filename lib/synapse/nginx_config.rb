require 'fileutils'
require 'tempfile'

module Synapse
  class NginxConfig
    include Logging
    attr_reader :opts, :name

    def initialize(opts)
      unless opts.has_key?("output_directory")
        raise ArgumentError, "flat file generation requires an output_directory key"
      end

      begin
        FileUtils.mkdir_p(opts['output_directory'])
      rescue SystemCallError => err
        raise ArgumentError, "provided output directory #{opts['output_directory']} is not present or creatable"
      end

      @opts = opts
      @name = 'nginx_config'
    end

    def tick(watchers)
    end

    def update_config(watchers)
      watchers.each do |watcher|
        write_backends_to_file(watcher.name, watcher.backends)
      end
      clean_old_watchers(watchers)
    end

    def write_backends_to_file(service_name, new_backends)
      data_path = File.join(@opts['output_directory'], "#{service_name}.conf")
        # Atomically write new sevice configuration file
        content = "upstream #{service_name} {
zone #{service_name} 128k;
#{new_backends.map{|b| "server #{b["host"]}:#{b["port"]}; "}.join("\n")}
}
"
        temp_path = File.join(@opts['output_directory'],
                              ".#{service_name}.conf.tmp")
        File.open(temp_path, 'w', 0644) {|f| f.write(content)}
        FileUtils.mv(temp_path, data_path)
        return true
    end

    def clean_old_watchers(current_watchers)
      # Cleanup old services that Synapse no longer manages
      FileUtils.cd(@opts['output_directory']) do
        present_files = Dir.glob('*.conf')
        managed_files = current_watchers.collect {|watcher| "#{watcher.name}.conf"}
        files_to_purge = present_files.select {|svc| not managed_files.include?(svc)}
        log.info "synapse: purging unknown service files #{files_to_purge}" if files_to_purge.length > 0
        FileUtils.rm(files_to_purge)
      end
    end
  end
end
