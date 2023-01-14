# frozen_string_literal: true

require 'devise'
require 'active_support/concern'
require_relative 'api/configuration'
require_relative 'api/version'
require_relative 'api/controllers/helpers'
require_relative 'api/responses/error_response'
require_relative 'api/responses/token_response'
require_relative 'api/generators/install_generator'

# rubocop:disable Style/ClassVars
module Devise
  mattr_accessor :api
  @@api = Devise::Api::Configuration.new

  module Models
    module Api
      extend ActiveSupport::Concern

      included do
        has_many :access_tokens,
                 class_name: Devise.api.config.base_token_model,
                 dependent: :destroy,
                 as: :resource_owner
      end

      class_methods do
        def supported_devise_modules
          devise_modules.inquiry
        end
      end
    end
  end

  module Api; end

  add_module :api,
             strategy: false,
             controller: :tokens,
             route: { api: %i[revoke refresh sign_up sign_in info] }
end
# rubocop:enable Style/ClassVars

ActiveSupport.on_load(:action_controller) do
  include Devise::Api::Controllers::Helpers
end

require_relative 'api/token'
require_relative 'api/rails/engine'
require_relative 'api/rails/routes'
