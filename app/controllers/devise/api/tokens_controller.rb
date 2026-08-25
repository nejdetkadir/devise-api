# frozen_string_literal: true

module Devise
  module Api
    class TokensController < Devise.api.config.base_controller.constantize
      wrap_parameters false
      skip_before_action :verify_authenticity_token, raise: false
      before_action :authenticate_devise_api_token!, only: %i[info]

      respond_to :json

      def sign_up
        return render_error_response(error: :sign_up_disabled) unless Devise.api.config.sign_up.enabled

        Devise.api.config.before_sign_up.call(sign_up_params, request, resource_class)

        service = Devise::Api::ResourceOwnerService::SignUp.new(params: sign_up_params,
                                                                resource_class: resource_class).call
        render_resource_owner_service_result(service, action: __method__)
      end

      def sign_in
        Devise.api.config.before_sign_in.call(sign_in_params, request, resource_class)

        service = Devise::Api::ResourceOwnerService::SignIn.new(params: sign_in_params,
                                                                resource_class: resource_class).call
        render_resource_owner_service_result(service, action: __method__)
      end

      def info
        render_token_response(current_devise_api_token, action: __method__)
      end

      def revoke
        Devise.api.config.before_revoke.call(current_devise_api_token, request)

        service = Devise::Api::TokensService::Revoke.new(devise_api_token: current_devise_api_token).call
        return render_error_response(**service.failure) if service.failure?

        token = service.success
        Devise.api.config.after_successful_revoke.call(token&.resource_owner, token, request)
        render_token_response(token, action: __method__)
      end

      def refresh
        return render_error_response(error: :refresh_token_disabled) unless Devise.api.config.refresh_token.enabled
        return render_error_response(error: :invalid_refresh_token) if current_devise_api_refresh_token.blank?
        return handle_refresh_token_reuse if refresh_token_reused?
        return render_error_response(error: :revoked_token) if current_devise_api_refresh_token.revoked?

        perform_refresh
      end

      private

      def perform_refresh
        Devise.api.config.before_refresh.call(current_devise_api_refresh_token, request)

        service = Devise::Api::TokensService::Refresh.new(devise_api_token: current_devise_api_refresh_token).call
        return render_error_response(**service.failure) if service.failure?

        token = service.success
        Devise.api.config.after_successful_refresh.call(token.resource_owner, token, request)
        render_token_response(token, action: :refresh)
      end

      def render_resource_owner_service_result(service, action:)
        return render_error_response(**service.failure) if service.failure?

        token = service.success
        call_devise_trackable!(token.resource_owner)
        Devise.api.config.public_send("after_successful_#{action}").call(token.resource_owner, token, request)
        render_token_response(token, action: action)
      end

      def render_token_response(token, action:)
        token_response = Devise::Api::Responses::TokenResponse.new(request, token: token, action: action)

        render json: token_response.body, status: token_response.status
      end

      def render_error_response(**failure)
        error_response = Devise::Api::Responses::ErrorResponse.new(request, resource_class: resource_class, **failure)

        render json: error_response.body, status: error_response.status
      end

      # A revoked or already-refreshed refresh token presented again while rotation is enabled means the
      # token was leaked or replayed: revoke the whole token family (OAuth2 Security BCP).
      def refresh_token_reused?
        Devise.api.config.refresh_token.rotation_enabled &&
          (current_devise_api_refresh_token.revoked? || current_devise_api_refresh_token.refreshes.exists?)
      end

      def handle_refresh_token_reuse
        current_devise_api_refresh_token.revoke_family!

        render_error_response(error: :revoked_token)
      end

      def sign_up_params
        params.permit(*Devise.api.config.sign_up.extra_fields, *resource_class.authentication_keys,
                      *::Devise::ParameterSanitizer::DEFAULT_PERMITTED_ATTRIBUTES[:sign_up]).to_h
      end

      def sign_in_params
        params.permit(*resource_class.authentication_keys,
                      *::Devise::ParameterSanitizer::DEFAULT_PERMITTED_ATTRIBUTES[:sign_in]).to_h
      end

      def call_devise_trackable!(resource_owner)
        return unless resource_class.supported_devise_modules.trackable?

        resource_owner.update_tracked_fields!(request)
      end
    end
  end
end
