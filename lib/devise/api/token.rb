# frozen_string_literal: true

require 'active_record'

module Devise
  module Api
    class Token < ::ActiveRecord::Base
      self.table_name = 'devise_api_tokens'

      # Redact raw token secrets from #inspect / pretty_print output (see also the
      # devise.api.filter_parameters engine initializer for request-log filtering)
      self.filter_attributes += %i[access_token refresh_token previous_refresh_token]

      # associations
      belongs_to :resource_owner,
                 polymorphic: true,
                 optional: false
      belongs_to :previous_refresh,
                 class_name: Devise.api.config.base_token_model,
                 foreign_key: :previous_refresh_token,
                 primary_key: :refresh_token,
                 optional: true
      has_many :refreshes,
               class_name: Devise.api.config.base_token_model,
               foreign_key: :previous_refresh_token,
               primary_key: :refresh_token

      # validations
      validates :access_token, presence: true, uniqueness: true
      validates :refresh_token,
                presence: true,
                uniqueness: true,
                if: -> { Devise.api.config.refresh_token.enabled }
      validates :expires_in,
                presence: true,
                numericality: { greater_than: 0 },
                unless: -> { Devise.api.config.access_token.expires_in_infinite.call(resource_owner) }

      def revoked?
        revoked_at.present?
      end

      def revoke!
        return self if revoked?

        update!(revoked_at: Time.current)
        self
      end

      # Revokes every token in this token's refresh chain (ancestors and descendants). Used for
      # refresh-token reuse detection when refresh_token.rotation_enabled is on.
      def revoke_family!
        transaction do
          family_tokens.each(&:revoke!)
        end
      end

      def active?
        !inactive?
      end

      def inactive?
        revoked? || expired?
      end

      def expired?
        return false if Devise.api.config.access_token.expires_in_infinite.call(resource_owner)

        !!(expires_in && Time.current > expires_at)
      end

      def refresh_token_expired?
        return false if Devise.api.config.refresh_token.expires_in_infinite.call(resource_owner)

        Time.current > refresh_token_expires_at
      end

      def self.generate_uniq_access_token(resource_owner)
        loop do
          token = Devise.api.config.access_token.generator.call(resource_owner)

          break token unless Devise.api.config.base_token_model.constantize.exists?(access_token: token)
        end
      end

      def self.generate_uniq_refresh_token(resource_owner)
        return nil unless Devise.api.config.refresh_token.enabled

        loop do
          token = Devise.api.config.refresh_token.generator.call(resource_owner)

          break token unless Devise.api.config.base_token_model.constantize.exists?(refresh_token: token)
        end
      end

      private

      def expires_at
        created_at + expires_in.seconds
      end

      def refresh_token_expires_at
        created_at + Devise.api.config.refresh_token.expires_in.seconds
      end

      def family_tokens
        root = self
        root = root.previous_refresh while root.previous_refresh.present?

        tokens = []
        queue = [root]
        while (token = queue.shift)
          tokens << token
          queue.concat(token.refreshes.to_a)
        end
        tokens
      end
    end
  end
end
