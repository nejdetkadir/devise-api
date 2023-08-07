# frozen_string_literal: true

module Devise
  module Api
    module TokensService
      class Refresh < Devise::Api::BaseService
        option :devise_api_token, type: Types.Instance(Devise.api.base_token_model.constantize)
        option :resource_owner, default: proc { devise_api_token.resource_owner }

        def call
          return Failure(error: :expired_refresh_token) if devise_api_token.refresh_token_expired?

          devise_api_token = yield create_devise_api_token
          Success(devise_api_token)
        end

        private

        def create_devise_api_token
          Devise::Api::TokensService::Create.new(resource_owner: resource_owner,
                                                 previous_refresh_token: devise_api_token.refresh_token).call
        end
      end
    end
  end
end
