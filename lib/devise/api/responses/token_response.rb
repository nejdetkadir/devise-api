# frozen_string_literal: true

module Devise
  module Api
    module Responses
      class TokenResponse
        attr_reader :request, :token, :action, :resource_owner

        ACTIONS = %i[
          sign_in
          sign_up
          refresh
          revoke
          info
        ].freeze

        ACTIONS.each do |act|
          define_method("#{act}_action?") do
            action.eql?(act)
          end
        end

        def initialize(request, token:, action:)
          @request = request
          @token = token
          @action = action
          @resource_owner = token&.resource_owner
        end

        def body
          return {} if revoke_action?
          return signed_up_body if sign_up_action?
          return info_body if info_action?

          default_body
        end

        def default_body
          {
            token: token.access_token,
            refresh_token: Devise.api.config.refresh_token.enabled ? token.refresh_token : nil,
            expires_in: token.expires_in,
            token_type: ::Devise.api.config.authorization.scheme,
            resource_owner: {
              id: resource_owner.id,
              email: resource_owner.email,
              created_at: resource_owner.created_at,
              updated_at: resource_owner.updated_at
            }
          }.compact
        end

        def status
          return :created if sign_up_action?
          return :no_content if revoke_action?

          :ok
        end

        private

        def signed_up_body
          return default_body unless resource_owner.class.supported_devise_modules.confirmable?

          message = resource_owner.confirmed? ? nil : I18n.t('devise.api.registerable.signed_up_but_unconfirmed')

          default_body.merge(confirmable: { confirmed: resource_owner.confirmed?, message: message }.compact)
        end

        def info_body
          default_body[:resource_owner]
        end
      end
    end
  end
end
