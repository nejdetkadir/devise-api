# frozen_string_literal: true

require 'active_support/concern'

module Devise
  module Api
    module Controllers
      module Helpers
        extend ActiveSupport::Concern

        def authenticate_devise_api_token!
          if current_devise_api_token.blank?
            error_response = Devise::Api::Responses::ErrorResponse.new(request, error: :invalid_token,
                                                                                resource_class: resource_class)

            return render json: error_response.body, status: error_response.status
          end

          if current_devise_api_token.expired?
            error_response = Devise::Api::Responses::ErrorResponse.new(request, error: :expired_token,
                                                                                resource_class: resource_class)

            return render json: error_response.body, status: error_response.status
          end

          return unless current_devise_api_token.revoked?

          error_response = Devise::Api::Responses::ErrorResponse.new(request, error: :revoked_token,
                                                                              resource_class: resource_class)

          render json: error_response.body, status: error_response.status
        end

        def current_devise_api_refresh_token
          token = find_devise_api_token

          Devise.api.config.base_token_model.constantize.find_by(refresh_token: token)
        end

        def current_devise_api_token
          return @current_devise_api_token if @current_devise_api_token

          token = find_devise_api_token
          devise_api_token_model = Devise.api.config.base_token_model.constantize
          @current_devise_api_token = devise_api_token_model.find_by(access_token: token)
        end

        def current_devise_api_user
          current_devise_api_token&.resource_owner
        end

        private

        def resource_class
          current_devise_api_user&.class
        end

        def extract_devise_api_token_from_params
          params[Devise.api.config.authorization.params_key]
        end

        def extract_devise_api_token_from_headers
          token = request.headers[Devise.api.config.authorization.key]
          unless token.blank?
            token = begin
              token.gsub(/^#{Devise.api.config.authorization.scheme} /,
                         '')
            rescue StandardError
              token
            end
          end
          token
        end

        def find_devise_api_token
          case Devise.api.config.authorization.location
          when :header
            extract_devise_api_token_from_headers
          when :params
            extract_devise_api_token_from_params
          when :both
            extract_devise_api_token_from_params || extract_devise_api_token_from_headers
          else
            raise ArgumentError, 'Invalid authorization location, must be :header, :params or :both'
          end
        end
      end
    end
  end
end
