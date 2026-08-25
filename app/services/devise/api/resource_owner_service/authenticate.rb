# frozen_string_literal: true

module Devise
  module Api
    module ResourceOwnerService
      class Authenticate < Devise::Api::BaseService
        option :params, type: Types::Hash
        option :resource_class, type: Types::Class

        def call
          resource = resource_class.find_for_authentication(params.slice(*resource_class.authentication_keys))
          return Failure(error: resource_not_found_error, record: nil) if resource.blank?
          return Failure(error: :invalid_authentication, record: resource) unless authenticate!(resource)

          Success(resource)
        end

        private

        def resource_not_found_error
          return :invalid_authentication if Devise.api.config.paranoid
          return :invalid_email if resource_class.authentication_keys.map(&:to_sym).include?(:email)

          :invalid_login
        end

        def authenticate!(resource)
          resource.valid_for_authentication? do
            resource.valid_password?(params[:password])
          end && resource.active_for_authentication?
        end
      end
    end
  end
end
