# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::Responses::ErrorResponse do
  context 'error types' do
    it 'has a list of error types' do
      expect(described_class::ERROR_TYPES).to eq %i[
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
      ]
    end

    it 'defines a helper method for each error type' do
      expect(described_class.new(nil, error: :invalid_token)).to respond_to(:invalid_token_error?)
      expect(described_class.new(nil, error: :expired_token)).to respond_to(:expired_token_error?)
      expect(described_class.new(nil, error: :expired_refresh_token)).to respond_to(:expired_refresh_token_error?)
      expect(described_class.new(nil, error: :revoked_token)).to respond_to(:revoked_token_error?)
      expect(described_class.new(nil, error: :refresh_token_disabled)).to respond_to(:refresh_token_disabled_error?)
      expect(described_class.new(nil, error: :sign_up_disabled)).to respond_to(:sign_up_disabled_error?)
      expect(described_class.new(nil, error: :invalid_refresh_token)).to respond_to(:invalid_refresh_token_error?)
      expect(described_class.new(nil, error: :invalid_email)).to respond_to(:invalid_email_error?)
      expect(described_class.new(nil, error: :invalid_resource_owner)).to respond_to(:invalid_resource_owner_error?)
      expect(described_class.new(nil, error: :resource_owner_create_error)).to respond_to(:resource_owner_create_error?)
      expect(described_class.new(nil,
                                 error: :devise_api_token_create_error)).to respond_to(:devise_api_token_create_error?)
      expect(described_class.new(nil,
                                 error: :devise_api_token_revoke_error)).to respond_to(:devise_api_token_revoke_error?)
      expect(described_class.new(nil, error: :invalid_authentication)).to respond_to(:invalid_authentication_error?)
    end
  end

  context 'invalid token error response' do
    let(:error_response) { described_class.new(nil, error: :invalid_token) }

    it 'has a status of 401' do
      expect(error_response.status).to eq :unauthorized
    end

    it 'has a body with an error and error description' do
      allow(I18n).to receive(:t).with('devise.api.error_response.invalid_token').and_return('Invalid token')

      expect(error_response.body).to eq(
        error: :invalid_token,
        error_description: ['Invalid token']
      )

      expect(I18n).to have_received(:t).with('devise.api.error_response.invalid_token')
    end
  end

  context 'expired token error response' do
    let(:error_response) { described_class.new(nil, error: :expired_token) }

    it 'has a status of 401' do
      expect(error_response.status).to eq :unauthorized
    end

    it 'has a body with an error and error description' do
      allow(I18n).to receive(:t).with('devise.api.error_response.expired_token').and_return('Expired token')

      expect(error_response.body).to eq(
        error: :expired_token,
        error_description: ['Expired token']
      )

      expect(I18n).to have_received(:t).with('devise.api.error_response.expired_token')
    end
  end

  context 'expired refresh token error response' do
    let(:error_response) { described_class.new(nil, error: :expired_refresh_token) }

    it 'has a status of 401' do
      expect(error_response.status).to eq :unauthorized
    end

    it 'has a body with an error and error description' do
      allow(I18n).to receive(:t)
        .with('devise.api.error_response.expired_refresh_token')
        .and_return('Expired refresh token')

      expect(error_response.body).to eq(
        error: :expired_refresh_token,
        error_description: ['Expired refresh token']
      )

      expect(I18n).to have_received(:t).with('devise.api.error_response.expired_refresh_token')
    end
  end

  context 'revoked token error response' do
    let(:error_response) { described_class.new(nil, error: :revoked_token) }

    it 'has a status of 401' do
      expect(error_response.status).to eq :unauthorized
    end

    it 'has a body with an error and error description' do
      allow(I18n).to receive(:t).with('devise.api.error_response.revoked_token').and_return('Revoked token')

      expect(error_response.body).to eq(
        error: :revoked_token,
        error_description: ['Revoked token']
      )

      expect(I18n).to have_received(:t).with('devise.api.error_response.revoked_token')
    end
  end

  context 'refresh token disabled error response' do
    let(:error_response) { described_class.new(nil, error: :refresh_token_disabled) }

    it 'has a status of 400' do
      expect(error_response.status).to eq :bad_request
    end

    it 'has a body with an error and error description' do
      allow(I18n).to receive(:t)
        .with('devise.api.error_response.refresh_token_disabled')
        .and_return('Refresh token disabled')

      expect(error_response.body).to eq(
        error: :refresh_token_disabled,
        error_description: ['Refresh token disabled']
      )

      expect(I18n).to have_received(:t).with('devise.api.error_response.refresh_token_disabled')
    end
  end

  context 'sign up disabled error response' do
    let(:error_response) { described_class.new(nil, error: :sign_up_disabled) }

    it 'has a status of 400' do
      expect(error_response.status).to eq :bad_request
    end

    it 'has a body with an error and error description' do
      allow(I18n).to receive(:t)
                       .with('devise.api.error_response.sign_up_disabled')
                       .and_return('Sign up is disabled')

      expect(error_response.body).to eq(
                                       error: :sign_up_disabled,
                                       error_description: ['Sign up is disabled']
                                     )

      expect(I18n).to have_received(:t).with('devise.api.error_response.sign_up_disabled')
    end
  end

  context 'invalid refresh token error response' do
    let(:error_response) { described_class.new(nil, error: :invalid_refresh_token) }

    it 'has a status of 400' do
      expect(error_response.status).to eq :bad_request
    end

    it 'has a body with an error and error description' do
      allow(I18n).to receive(:t)
        .with('devise.api.error_response.invalid_refresh_token')
        .and_return('Invalid refresh token')

      expect(error_response.body).to eq(
        error: :invalid_refresh_token,
        error_description: ['Invalid refresh token']
      )

      expect(I18n).to have_received(:t).with('devise.api.error_response.invalid_refresh_token')
    end
  end

  context 'invalid email error response' do
    let(:error_response) { described_class.new(nil, error: :invalid_email) }

    it 'has a status of 400' do
      expect(error_response.status).to eq :bad_request
    end

    it 'has a body with an error and error description' do
      allow(I18n).to receive(:t)
        .with('devise.api.error_response.invalid_email')
        .and_return('Invalid email')

      expect(error_response.body).to eq(
        error: :invalid_email,
        error_description: ['Invalid email']
      )

      expect(I18n).to have_received(:t).with('devise.api.error_response.invalid_email')
    end
  end

  context 'invalid resource owner error response' do
    let(:error_response) { described_class.new(nil, error: :invalid_resource_owner) }

    it 'has a status of 400' do
      expect(error_response.status).to eq :bad_request
    end

    it 'has a body with an error and error description' do
      allow(I18n).to receive(:t)
        .with('devise.api.error_response.invalid_resource_owner')
        .and_return('Invalid resource owner')

      expect(error_response.body).to eq(
        error: :invalid_resource_owner,
        error_description: ['Invalid resource owner']
      )

      expect(I18n).to have_received(:t).with('devise.api.error_response.invalid_resource_owner')
    end
  end

  context 'resource owner create error response' do
    let(:record) { double('record', errors: double('errors', full_messages: ['error message'])) }
    let(:error_response) { described_class.new(nil, error: :resource_owner_create_error, record: record) }

    it 'has a status of 422' do
      expect(error_response.status).to eq :unprocessable_entity
    end

    it 'has a body with an error and error description' do
      expect(error_response.body).to eq(
        error: :resource_owner_create_error,
        error_description: ['error message']
      )

      expect(record).to have_received(:errors)
      expect(record.errors).to have_received(:full_messages)
    end
  end

  context 'devise api token create error response' do
    let(:record) { double('record', errors: double('errors', full_messages: ['error message'])) }
    let(:error_response) { described_class.new(nil, error: :devise_api_token_create_error, record: record) }

    it 'has a status of 422' do
      expect(error_response.status).to eq :unprocessable_entity
    end

    it 'has a body with an error and error description' do
      expect(error_response.body).to eq(
        error: :devise_api_token_create_error,
        error_description: ['error message']
      )

      expect(record).to have_received(:errors)
      expect(record.errors).to have_received(:full_messages)
    end
  end

  context 'devise api token revoke error response' do
    let(:record) { double('record', errors: double('errors', full_messages: ['error message'])) }
    let(:error_response) { described_class.new(nil, error: :devise_api_token_revoke_error, record: record) }

    it 'has a status of 422' do
      expect(error_response.status).to eq :unprocessable_entity
    end

    it 'has a body with an error and error description' do
      expect(error_response.body).to eq(
        error: :devise_api_token_revoke_error,
        error_description: ['error message']
      )

      expect(record).to have_received(:errors)
      expect(record.errors).to have_received(:full_messages)
    end
  end

  context 'invalid authentication error response' do
    context 'normal' do
      let(:error_response) { described_class.new(nil, error: :invalid_authentication) }

      it 'has a status of 401' do
        expect(error_response.status).to eq :unauthorized
      end

      it 'has a body with an error and error description' do
        allow(I18n).to receive(:t)
          .with('devise.api.error_response.invalid_authentication')
          .and_return('Invalid authentication')

        expect(error_response.body).to eq(
          error: :invalid_authentication,
          error_description: ['Invalid authentication']
        )

        expect(I18n).to have_received(:t).with('devise.api.error_response.invalid_authentication')
      end
    end
  end

  context 'with lockable' do
    let(:record) { double('record', access_locked?: false, failed_attempts: 0, locked_at: nil) }
    let(:resource_class) { double('resource_class', supported_devise_modules: [:lockable]) }
    let(:error_response) do
      described_class.new(nil, error: :invalid_authentication, record: record, resource_class: resource_class)
    end

    it 'has a body with an error and error description' do
      allow(resource_class.supported_devise_modules).to receive(:lockable?).and_return(true)
      allow(resource_class.supported_devise_modules).to receive(:confirmable?).and_return(false)
      allow(record).to receive(:confirmed?).and_return(false)
      allow(record).to receive(:access_locked?).and_return(false)
      allow(I18n).to receive(:t)
        .with('devise.api.error_response.invalid_authentication')
        .and_return('Invalid authentication')

      expect(error_response.body).to eq(
        error: :invalid_authentication,
        error_description: ['Invalid authentication'],
        lockable: {
          locked: false,
          max_attempts: ::Devise.maximum_attempts,
          failed_attemps: 0
        }
      )

      expect(I18n).to have_received(:t).with('devise.api.error_response.invalid_authentication')
    end
  end

  context 'with confirmable' do
    let(:record) { double('record', confirmed?: false, confirmation_sent_at: nil) }
    let(:resource_class) { double('resource_class', supported_devise_modules: [:confirmable]) }
    let(:error_response) do
      described_class.new(nil, error: :invalid_authentication, record: record, resource_class: resource_class)
    end

    it 'has a body with an error and error description' do
      allow(resource_class.supported_devise_modules).to receive(:lockable?).and_return(false)
      allow(resource_class.supported_devise_modules).to receive(:confirmable?).and_return(true)
      allow(record).to receive(:confirmed?).and_return(false)
      allow(record).to receive(:access_locked?).and_return(false)
      allow(I18n).to receive(:t)
        .with('devise.api.error_response.confirmable.unconfirmed')
        .and_return('Unconfirmed')

      expect(error_response.body).to eq(
        error: :invalid_authentication,
        error_description: ['Unconfirmed'],
        confirmable: {
          confirmed: false
        }
      )

      expect(I18n).to have_received(:t).with('devise.api.error_response.confirmable.unconfirmed')
    end
  end
end
