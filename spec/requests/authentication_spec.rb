# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'GET /home' do
    context 'when the token is valid and on the header' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

      before do
        get home_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns the correct response' do
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to eql({ 'success' => true })
      end
    end

    context 'when the token is valid and on the url param' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

      before do
        get home_path(access_token: devise_api_token.access_token), as: :json
      end

      it 'returns the correct response' do
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to eql({ 'success' => true })
      end
    end

    context 'when the token is invalid and on the header' do
      let(:user) { create(:user) }
      let(:devise_api_token) { build(:devise_api_token, resource_owner: user) }

      before do
        get home_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'invalid_token'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.invalid_token')])
      end

      it 'does not return the authenticated resource owner' do
        expect(parsed_body.id).to be_nil
        expect(parsed_body.email).to be_nil
        expect(parsed_body.created_at).to be_nil
        expect(parsed_body.updated_at).to be_nil
      end
    end

    context 'when the token is invalid and on the url param' do
      before do
        get home_path(access_token: 'invalid'), as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'invalid_token'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.invalid_token')])
      end

      it 'does not return the authenticated resource owner' do
        expect(parsed_body.id).to be_nil
        expect(parsed_body.email).to be_nil
        expect(parsed_body.created_at).to be_nil
        expect(parsed_body.updated_at).to be_nil
      end
    end

    context 'when the token is expired' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, :access_token_expired, resource_owner: user) }

      before do
        get home_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'expired_token'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.expired_token')])
      end

      it 'does not return the authenticated resource owner' do
        expect(parsed_body.id).to be_nil
        expect(parsed_body.email).to be_nil
        expect(parsed_body.created_at).to be_nil
        expect(parsed_body.updated_at).to be_nil
      end
    end

    context 'when the token is revoked' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, :revoked, resource_owner: user) }

      before do
        get home_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'revoked_token'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.revoked_token')])
      end

      it 'does not return the authenticated resource owner' do
        expect(parsed_body.id).to be_nil
        expect(parsed_body.email).to be_nil
        expect(parsed_body.created_at).to be_nil
        expect(parsed_body.updated_at).to be_nil
      end
    end
  end
end
