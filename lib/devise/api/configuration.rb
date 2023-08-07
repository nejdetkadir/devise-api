# frozen_string_literal: true

require 'dry-configurable'

module Devise
  module Api
    class Configuration
      include Dry::Configurable

      setting :access_token, reader: true do
        setting :expires_in, default: 1.hour, reader: true
        setting :expires_in_infinite, default: proc { |_resource_owner| false }, reader: true
        setting :generator, default: proc { |_resource_owner| ::Devise.friendly_token(60) }, reader: true
      end

      setting :refresh_token, reader: true do
        setting :enabled, default: true, reader: true
        setting :expires_in, default: 1.week, reader: true
        setting :generator, default: proc { |_resource_owner| ::Devise.friendly_token(60) }, reader: true
        setting :expires_in_infinite, default: proc { |_resource_owner| false }, reader: true
      end

      setting :sign_up, reader: true do
        setting :enabled, default: true, reader: true
      end

      setting :authorization, reader: true do
        setting :key, default: 'Authorization', reader: true
        setting :scheme, default: 'Bearer', reader: true
        setting :location, default: :both, reader: true # :header or :params or :both
        setting :params_key, default: 'access_token', reader: true
      end

      setting :base_token_model, default: 'Devise::Api::Token', reader: true
      setting :base_controller, default: '::DeviseController', reader: true

      setting :after_successful_sign_in, default: proc { |_resource_owner, _token, _request| }, reader: true
      setting :after_successful_sign_up, default: proc { |_resource_owner, _token, _request| }, reader: true
      setting :after_successful_refresh, default: proc { |_resource_owner, _token, _request| }, reader: true
      setting :after_successful_revoke, default: proc { |_resource_owner, _token, _request| }, reader: true

      setting :before_sign_in, default: proc { |_params, _request, _resource_class| }, reader: true
      setting :before_sign_up, default: proc { |_params, _request, _resource_class| }, reader: true
      setting :before_refresh, default: proc { |_token, _request| }, reader: true
      setting :before_revoke, default: proc { |_token, _request| }, reader: true
    end
  end
end
