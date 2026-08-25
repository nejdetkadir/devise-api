# frozen_string_literal: true

require 'spec_helper'

# Covers refresh_token.rotation_enabled (SEC-2): rotating out the presented refresh token and
# revoking the whole token family when a rotated refresh token is replayed.
RSpec.describe Devise::Api::TokensController, type: :request do
  describe 'POST /users/tokens/refresh' do
    let(:user) { create(:user) }
    let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

    context 'when rotation is disabled (default)' do
      before do
        post refresh_user_tokens_path, headers: authentication_headers_for(user, devise_api_token, :refresh_token),
                                       as: :json
      end

      it 'keeps the presented refresh token usable' do
        expect(devise_api_token.reload.revoked?).to eq false

        post refresh_user_tokens_path, headers: authentication_headers_for(user, devise_api_token, :refresh_token),
                                       as: :json

        expect(response).to have_http_status(:success)
      end
    end

    context 'when rotation is enabled' do
      around do |example|
        original = Devise.api.config.refresh_token.rotation_enabled
        Devise.api.config.refresh_token.rotation_enabled = true
        example.run
      ensure
        Devise.api.config.refresh_token.rotation_enabled = original
      end

      context 'and the refresh token is presented for the first time' do
        before do
          post refresh_user_tokens_path, headers: authentication_headers_for(user, devise_api_token, :refresh_token),
                                         as: :json
        end

        it 'returns http success with a new token' do
          expect(response).to have_http_status(:success)
          expect(parsed_body.token).to be_present
          expect(parsed_body.refresh_token).not_to eq(devise_api_token.refresh_token)
        end

        it 'revokes the presented refresh token' do
          expect(devise_api_token.reload.revoked?).to eq true
        end

        it 'links the new token to the presented one' do
          expect(devise_api_token.refreshes.count).to eq(1)
        end
      end

      context 'and a rotated refresh token is replayed' do
        before do
          post refresh_user_tokens_path, headers: authentication_headers_for(user, devise_api_token, :refresh_token),
                                         as: :json
          post refresh_user_tokens_path, headers: authentication_headers_for(user, devise_api_token, :refresh_token),
                                         as: :json
        end

        it 'returns http unauthorized' do
          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns a revoked token error response' do
          expect(parsed_body.error).to eq 'revoked_token'
          expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.revoked_token')])
        end

        it 'revokes the whole token family' do
          expect(Devise::Api::Token.count).to eq(2)
          expect(Devise::Api::Token.all).to all(be_revoked)
        end
      end

      context 'and an unrevoked refresh token that was already refreshed before rotation is replayed' do
        let!(:successor) do
          create(:devise_api_token, resource_owner: user, previous_refresh_token: devise_api_token.refresh_token)
        end

        before do
          post refresh_user_tokens_path, headers: authentication_headers_for(user, devise_api_token, :refresh_token),
                                         as: :json
        end

        it 'returns http unauthorized with a revoked token error' do
          expect(response).to have_http_status(:unauthorized)
          expect(parsed_body.error).to eq 'revoked_token'
        end

        it 'revokes the whole token family' do
          expect(devise_api_token.reload.revoked?).to eq true
          expect(successor.reload.revoked?).to eq true
        end
      end
    end
  end
end
