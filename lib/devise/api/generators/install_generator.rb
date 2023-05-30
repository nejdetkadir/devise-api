# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'
require 'rails/generators/active_model'

module Devise
  module Api
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        include ::Rails::Generators::Migration
        source_root File.expand_path('templates', __dir__)
        desc 'Generates a migration to add the required fields to the your devise model'
        namespace 'devise_api:install'

        def install
          migration_template(
            'migration.rb.erb',
            'db/migrate/create_devise_api_tables.rb',
            migration_version: migration_version
          )

          copy_file locale_source, locale_destination
        end

        def self.next_migration_number(path)
          ActiveRecord::Generators::Base.next_migration_number(path)
        end

        private

        def locale_source
          File.expand_path('../../../../config/locales/en.yml', __dir__)
        end

        def locale_destination
          'config/locales/devise_api.en.yml'
        end

        def migration_version
          "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
        end
      end
    end
  end
end
