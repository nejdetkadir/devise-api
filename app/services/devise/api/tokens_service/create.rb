# frozen_string_literal: true

module Devise
  module Api
    module TokensService
      class Create < Devise::Api::BaseService
        option :resource_owner
        option :previous_refresh_token, type: Types::String | Types::Nil, default: proc { nil }

        def call
          return Failure(error: :invalid_resource_owner) unless resource_owner.respond_to?(:access_tokens)

          devise_api_token = yield create_devise_api_token

          Success(devise_api_token)
        end

        private

        def authenticate_service
          Devise::Api::ResourceOwnerService::Authenticate.new(params: params,
                                                              resource_class: resource_class).call
        end

        def create_devise_api_token
          devise_api_token = resource_owner.access_tokens.new(params)

          return Success(devise_api_token) if devise_api_token.save

          Failure(error: :devise_api_token_create_error, record: devise_api_token)
        end

        def params
          {
            access_token: Devise.api.config.base_token_model.constantize.generate_uniq_access_token(resource_owner),
            refresh_token: Devise.api.config.base_token_model.constantize.generate_uniq_refresh_token(resource_owner),
            expires_in: Devise.api.config.access_token.expires_in,
            revoked_at: nil,
            previous_refresh_token: previous_refresh_token
          }
        end
      end
    end
  end
end
