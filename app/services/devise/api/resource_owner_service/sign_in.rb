# frozen_string_literal: true

module Devise
  module Api
    module ResourceOwnerService
      class SignIn < Devise::Api::BaseService
        option :params, type: Types::Hash
        option :resource_class, type: Types::Class

        def call
          resource_owner = yield call_authenticate_service
          devise_api_token = yield call_create_devise_api_token_service(resource_owner)
          resource_owner.reset_failed_attempts! if resource_owner.class.supported_devise_modules.lockable?

          Success(devise_api_token)
        end

        private

        def call_authenticate_service
          Devise::Api::ResourceOwnerService::Authenticate.new(params: params,
                                                              resource_class: resource_class).call
        end

        def call_create_devise_api_token_service(resource_owner)
          Devise::Api::TokensService::Create.new(resource_owner: resource_owner).call
        end
      end
    end
  end
end
