# frozen_string_literal: true
require 'rails/generators/base'
require_relative 'install_mixin.rb'

module Searchable
  class InstallGenerator < Rails::Generators::Base
    include InstallMixin
    desc 'Installing searchable: creates searchable table for storing searchable data.'
    source_root File.expand_path("../templates/", __FILE__)

    def create_migration
      template 'install_migration.rb', "#{migration_path}_create_searchable_indices.rb", migration_version: migration_version
    end

    def update_sidekiq_config
      puts "Would you like to configure sidekiq? (y/n)"
      response = gets.chomp
      if ((/\s*yes\s*/i) =~ response) || ((/\s*y\s*/i) =~ response)
        generate "searchable:sidekiq_config"
      end
    end

    def print_status
      puts "Created install migration. Run `rails db:migrate` to install the table `searchable_indices`."
    end
  end
end
