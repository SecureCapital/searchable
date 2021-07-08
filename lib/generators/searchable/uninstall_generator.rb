# frozen_string_literal: true
require 'rails/generators/base'
require_relative 'install_mixin.rb'

module Searchable
  class UninstallGenerator < Rails::Generators::Base
    include InstallMixin
    desc "Uninstalling Searchableable: adds miration to remove searchable_indices"
    source_root File.expand_path("../templates/", __FILE__)

    def create_migration
      template 'uninstall_migration.rb', "#{migration_path}_drop_searchable_indices.rb", migration_version: migration_version
    end

    def print_status
      puts %Q(Uninstall migration created. Remember to remove 'searchable' from gemfile, any configuration of Searchable, and all implementations in your models.)
    end

    private
    def remove_file(path)
      puts "Would you like to remove #{path}? (y/n)"
      response = gets.chomp
      if ((/\s*yes\s*/i) =~ response) || ((/\s*y\s*/i) =~ response)
        if block_given?
          yield
        else
          puts File.delete(path) if File.exist?(path)
        end
      end
    end
  end
end
