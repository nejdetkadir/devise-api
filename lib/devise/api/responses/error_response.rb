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
          invalid_resource_owner
          resource_owner_create_error
          devise_api_token_create_error
          devise_api_token_revoke_error
          invalid_authentication
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

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def error_description
          return [I18n.t("devise.api.error_response.#{error}")] if record.blank?
          if invalid_authentication_error? && devise_lockable_info.present? && record.access_locked?
            return [I18n.t('devise.api.error_response.lockable.locked')]
          end
          if invalid_authentication_error? && devise_confirmable_info.present? && !record.confirmed?
            return [I18n.t('devise.api.error_response.confirmable.unconfirmed')]
          end
          return [I18n.t('devise.api.error_response.invalid_authentication')] if invalid_authentication_error?

          record.errors.full_messages
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def devise_lockable_info
          unless resource_class.present? &&
                 resource_class.supported_devise_modules.lockable? &&
                 invalid_authentication_error?
            return nil
          end

          unlock_at = record.access_locked? ? record.locked_at + ::Devise.unlock_in : nil

          {
            locked: record.access_locked?,
            max_attempts: ::Devise.maximum_attempts,
            failed_attemps: record.failed_attempts,
            locked_at: record.locked_at,
            unlock_at: unlock_at
          }.compact
        end

        def devise_confirmable_info
          unless resource_class.present? &&
                 resource_class.supported_devise_modules.confirmable? &&
                 invalid_authentication_error?
            return nil
          end

          {
            confirmed: record.confirmed?,
            confirmation_sent_at: record.confirmed? ? nil : record.confirmation_sent_at
          }.compact
        end

        def unauthorized_status?
          invalid_token_error? ||
            expired_token_error? ||
            expired_refresh_token_error? ||
            revoked_token_error? ||
            invalid_authentication_error?
        end

        def bad_request_status?
          invalid_email_error? ||
            invalid_refresh_token_error? ||
            refresh_token_disabled_error? ||
            sign_up_disabled_error? ||
            invalid_resource_owner_error?
        end
      end
    end
  end
end
