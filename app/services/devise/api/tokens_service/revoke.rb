# frozen_string_literal: true

module Devise
  module Api
    module TokensService
      class Revoke < Devise::Api::BaseService
        option :devise_api_token, optional: true

        def call
          return Success(devise_api_token) if devise_api_token.blank?
          return Success(devise_api_token) if devise_api_token.revoked? || devise_api_token.expired?
          return Success(devise_api_token) if devise_api_token.update(revoked_at: Time.zone.now)

          Failure(error: :devise_api_token_revoke_error, record: devise_api_token)
        end
      end
    end
  end
end
