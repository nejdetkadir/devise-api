# frozen_string_literal: true

module Devise
  module Api
    module TokensService
      class Refresh < Devise::Api::BaseService
        option :devise_api_token, type: Types.Instance(Devise.api.base_token_model.constantize)
        option :resource_owner, default: proc { devise_api_token.resource_owner }

        def call
          return Failure(error: :expired_refresh_token) if devise_api_token.refresh_token_expired?
          return create_devise_api_token unless Devise.api.config.refresh_token.rotation_enabled

          create_devise_api_token_with_rotation
        end

        private

        def create_devise_api_token
          Devise::Api::TokensService::Create.new(resource_owner: resource_owner,
                                                 previous_refresh_token: devise_api_token.refresh_token).call
        end

        # Mints the replacement token and revokes the presented refresh token atomically, so a
        # rotated refresh token can never be replayed (its reuse triggers family revocation upstream)
        def create_devise_api_token_with_rotation
          result = nil

          devise_api_token.class.transaction do
            result = create_devise_api_token
            raise ::ActiveRecord::Rollback if result.failure?

            devise_api_token.revoke!
          end

          result
        end
      end
    end
  end
end
