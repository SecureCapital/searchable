module Searchable
  class SidekiqConfigGenerator < Rails::Generators::Base
    def create_config
      unless config_defined?
        puts "Creating file #{file_name}"
        create_file file_name
      end
    end

    def add_queue
      config[:queues] = [] unless config[:queues]
      unless config[:queues].include? 'searchable'
        puts "Adding queue `searchable`"
        config[:queues] << 'searchable'
      end
    end

    def add_queue_limits
      config[:limits] = {} unless config[:limits]
      unless config[:limits].keys.include? 'searchable'
        puts "Setting queue limit `searchable` to 2"
        config[:limits].update('searchable' => 2)
      end
    end

    def save_config
      puts "Saving configuration"
      File.write(file_name, config.to_yaml)
    end

    private
    def config
      @config ||= (YAML::load(File.open(file_name)) || {})
    end

    def file_name
      "#{::Rails.root}/config/sidekiq.yml"
    end

    def config_defined?
      File.file?(file_name)
    end
  end
end
