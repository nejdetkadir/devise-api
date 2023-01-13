# frozen_string_literal: true

module Devise
  module Api
    module TokensService
      class Revoke < Devise::Api::BaseService
        option :devise_api_token

        def call
          return Failure(:invalid_token) if devise_api_token.blank?
          return Success(devise_api_token) if devise_api_token.update(revoked_at: Time.zone.now)

          Failure(error: :devise_api_token_revoke_error, record: devise_api_token)
        end
      end
    end
  end
end
