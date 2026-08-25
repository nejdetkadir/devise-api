# frozen_string_literal: true

module Devise
  module Api
    module TokensService
      class Create < Devise::Api::BaseService
        # Retries after ActiveRecord::RecordNotUnique when two concurrent requests win the
        # application-level uniqueness check with the same generated token (see unique DB indexes)
        MAX_TOKEN_GENERATION_ATTEMPTS = 3

        option :resource_owner
        option :previous_refresh_token, type: Types::String | Types::Nil, default: proc { nil }

        def call
          return Failure(error: :invalid_resource_owner) unless resource_owner.respond_to?(:access_tokens)

          devise_api_token = yield create_devise_api_token

          Success(devise_api_token)
        end

        private

        def create_devise_api_token
          attempts = 0

          begin
            devise_api_token = resource_owner.access_tokens.new(params)

            return Success(devise_api_token) if devise_api_token.save

            Failure(error: :devise_api_token_create_error, record: devise_api_token)
          rescue ::ActiveRecord::RecordNotUnique
            attempts += 1
            retry if attempts < MAX_TOKEN_GENERATION_ATTEMPTS

            raise
          end
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
