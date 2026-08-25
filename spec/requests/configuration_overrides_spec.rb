# frozen_string_literal: true

require 'spec_helper'

# Devise.api.config is a global, so every override here is assigned inside an around
# block and restored in its ensure clause to avoid leaking into other examples.
RSpec.describe Devise::Api::TokensController, type: :request do
  describe 'POST /users/tokens/sign_up' do
    context 'when sign up is disabled' do
      let(:params) { attributes_for(:user) }

      around do |example|
        original = Devise.api.config.sign_up.enabled
        Devise.api.config.sign_up.enabled = false
        example.run
      ensure
        Devise.api.config.sign_up.enabled = original
      end

      before do
        post sign_up_user_tokens_path, params: params, as: :json
      end

      it 'returns http bad request' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'sign_up_disabled'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.sign_up_disabled')])
      end

      it 'does not create a user' do
        expect(User.count).to eq(0)
      end
    end

    context 'when extra fields are configured' do
      let(:params) { attributes_for(:user).merge(name: 'John Doe') }

      around do |example|
        original = Devise.api.config.sign_up.extra_fields
        Devise.api.config.sign_up.extra_fields = [:name]
        example.run
      ensure
        Devise.api.config.sign_up.extra_fields = original
      end

      before do
        post sign_up_user_tokens_path, params: params, as: :json
      end

      it 'returns http success' do
        expect(response).to have_http_status(:created)
      end

      it 'returns the extra fields on the resource owner' do
        expect(parsed_body.resource_owner.name).to eq('John Doe')
      end

      it 'persists the extra fields' do
        expect(User.last.name).to eq('John Doe')
      end
    end
  end

  describe 'POST /users/tokens/refresh' do
    context 'when refresh tokens are disabled' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

      around do |example|
        original = Devise.api.config.refresh_token.enabled
        Devise.api.config.refresh_token.enabled = false
        example.run
      ensure
        Devise.api.config.refresh_token.enabled = original
      end

      before do
        post refresh_user_tokens_path,
             headers: authentication_headers_for(user, devise_api_token, :refresh_token),
             as: :json
      end

      it 'returns http bad request' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'refresh_token_disabled'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.refresh_token_disabled')])
      end
    end
  end

  describe 'POST /users/tokens/revoke' do
    context 'when the revoke service fails' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }
      let(:failure) do
        Dry::Monads::Result::Failure.new(error: :devise_api_token_revoke_error, record: devise_api_token)
      end

      before do
        service = instance_double(Devise::Api::TokensService::Revoke, call: failure)
        allow(Devise::Api::TokensService::Revoke).to receive(:new).and_return(service)

        post revoke_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'devise_api_token_revoke_error'
      end

      it 'does not revoke the token' do
        expect(devise_api_token.reload.revoked?).to eq false
      end
    end
  end

  describe 'GET /home' do
    let(:user) { create(:user) }
    let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

    context 'when the authorization location is :header' do
      around do |example|
        original = Devise.api.config.authorization.location
        Devise.api.config.authorization.location = :header
        example.run
      ensure
        Devise.api.config.authorization.location = original
      end

      context 'and the token is on the header' do
        before do
          get home_path, headers: authentication_headers_for(user, devise_api_token), as: :json
        end

        it 'returns http success' do
          expect(response).to have_http_status(:success)
        end
      end

      context 'and the token is on the url param' do
        before do
          get home_path(access_token: devise_api_token.access_token), as: :json
        end

        it 'returns http unauthorized' do
          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns an error response' do
          expect(parsed_body.error).to eq 'invalid_token'
        end
      end
    end

    context 'when the authorization location is :params' do
      around do |example|
        original = Devise.api.config.authorization.location
        Devise.api.config.authorization.location = :params
        example.run
      ensure
        Devise.api.config.authorization.location = original
      end

      context 'and the token is on the url param' do
        before do
          get home_path(access_token: devise_api_token.access_token), as: :json
        end

        it 'returns http success' do
          expect(response).to have_http_status(:success)
        end
      end

      context 'and the token is on the header' do
        before do
          get home_path, headers: authentication_headers_for(user, devise_api_token), as: :json
        end

        it 'returns http unauthorized' do
          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns an error response' do
          expect(parsed_body.error).to eq 'invalid_token'
        end
      end
    end
  end
end
