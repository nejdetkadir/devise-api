# frozen_string_literal: true

module Devise
  module Api
    module Responses
      class ErrorResponse
        attr_reader :request, :error, :record, :resource_class

        ERROR_TYPES = %i[
          invalid_token
          expired_token
          expired_refresh_token
          revoked_token
          refresh_token_disabled
          sign_up_disabled
          invalid_refresh_token
          invalid_email
          invalid_login
          invalid_resource_owner
          resource_owner_create_error
          devise_api_token_create_error
          devise_api_token_revoke_error
          invalid_authentication
        ].freeze

        UNAUTHORIZED_ERRORS = %i[
          invalid_token expired_token expired_refresh_token revoked_token invalid_authentication
        ].freeze

        BAD_REQUEST_ERRORS = %i[
          invalid_email invalid_login invalid_refresh_token refresh_token_disabled sign_up_disabled
          invalid_resource_owner
        ].freeze

        ERROR_TYPES.each do |error_type|
          method_name = error_type.end_with?('_error') ? error_type : "#{error_type}_error"

          define_method("#{method_name}?") do
            error.eql?(error_type)
          end
        end

        def initialize(request, error:, record: nil, resource_class: nil)
          @request = request
          @error = error
          @record = record
          @resource_class = resource_class
        end

        def body
          {
            error: error,
            error_description: error_description,
            lockable: devise_lockable_info,
            confirmable: devise_confirmable_info
          }.compact
        end

        def status
          return :unauthorized if unauthorized_status?
          return :bad_request if bad_request_status?

          :unprocessable_entity
        end

        private

        def error_description
          return [I18n.t("devise.api.error_response.#{error}")] if record.blank?
          return invalid_authentication_description if invalid_authentication_error?

          record.errors.full_messages
        end

        def invalid_authentication_description
          unless Devise.api.config.paranoid
            return [I18n.t('devise.api.error_response.lockable.locked')] if lockable_record? && record.access_locked?
            if confirmable_record? && !record.confirmed?
              return [I18n.t('devise.api.error_response.confirmable.unconfirmed')]
            end
          end

          [I18n.t('devise.api.error_response.invalid_authentication')]
        end

        def devise_lockable_info
          return nil unless verbose_account_state? && lockable_record? && invalid_authentication_error?

          unlock_at = record.access_locked? ? record.locked_at + ::Devise.unlock_in : nil

          {
            locked: record.access_locked?,
            max_attempts: ::Devise.maximum_attempts,
            failed_attempts: record.failed_attempts,
            # Deprecated misspelling kept for backward compatibility; will be removed in the next major release
            failed_attemps: record.failed_attempts,
            locked_at: record.locked_at,
            unlock_at: unlock_at
          }.compact
        end

        def devise_confirmable_info
          return nil unless verbose_account_state? && confirmable_record? && invalid_authentication_error?

          {
            confirmed: record.confirmed?,
            confirmation_sent_at: record.confirmed? ? nil : record.confirmation_sent_at
          }.compact
        end

        def lockable_record?
          record.present? && resource_class.present? && resource_class.supported_devise_modules.lockable?
        end

        def confirmable_record?
          record.present? && resource_class.present? && resource_class.supported_devise_modules.confirmable?
        end

        def verbose_account_state?
          !Devise.api.config.paranoid && Devise.api.config.error_response.verbose_account_state
        end

        def unauthorized_status?
          UNAUTHORIZED_ERRORS.include?(error)
        end

        def bad_request_status?
          BAD_REQUEST_ERRORS.include?(error)
        end
      end
    end
  end
end
