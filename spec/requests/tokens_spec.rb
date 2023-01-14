# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::TokensController, type: :request do
  describe 'POST /users/tokens/sign_up' do
    context 'when the user is valid' do
      let(:params) { attributes_for(:user) }

      before do
        allow(Devise.api.config.after_successful_sign_up).to receive(:call).and_call_original
        allow(Devise.api.config.before_sign_up).to receive(:call).and_call_original

        post sign_up_user_tokens_path, params: params, as: :json
      end

      it 'returns http success' do
        expect(response).to have_http_status(:created)
      end

      it 'returns a token' do
        expect(parsed_body.token).to be_present
        expect(parsed_body.refresh_token).to be_present
        expect(parsed_body.expires_in).to eq(1.hour.to_i)
        expect(parsed_body.token_type).to eq('Bearer')
        expect(parsed_body.resource_owner).to be_present
        expect(parsed_body.resource_owner.id).to eq(User.last.id)
        expect(parsed_body.resource_owner.email).to eq(params[:email])
        expect(parsed_body.resource_owner.created_at).to be_present
        expect(parsed_body.resource_owner.updated_at).to be_present
      end

      it 'creates a user' do
        expect(User.count).to eq(1)
        expect(User.last.email).to eq(params[:email])
      end

      it 'creates a token' do
        expect(Devise::Api::Token.count).to eq(1)
        expect(Devise::Api::Token.last.access_token).to eq(parsed_body.token)
        expect(Devise::Api::Token.last.refresh_token).to eq(parsed_body.refresh_token)
        expect(Devise::Api::Token.last.expires_in).to eq 1.hour.to_i
        expect(Devise::Api::Token.last.resource_owner_id).to eq(User.last.id)
        expect(Devise::Api::Token.last.resource_owner_type).to eq('User')
      end

      it 'trackable is incremented' do
        expect(User.last.sign_in_count).to eq(1)
        expect(User.last.current_sign_in_at).to be_present
        expect(User.last.last_sign_in_at).to be_present
        expect(User.last.current_sign_in_ip).to be_present
        expect(User.last.last_sign_in_ip).to be_present
      end

      it 'calls the after_successful_sign_up and before_sign_up callbacks' do
        expect(Devise.api.config.after_successful_sign_up).to have_received(:call).once
        expect(Devise.api.config.before_sign_up).to have_received(:call).once
      end
    end

    context 'when the email is already taken' do
      let(:user) { create(:user) }
      let(:params) { attributes_for(:user, email: user.email) }

      before do
        allow(Devise.api.config.before_sign_up).to receive(:call).and_call_original

        post sign_up_user_tokens_path, params: params, as: :json
      end

      it 'returns http unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(parsed_body.error).to eq 'resource_owner_create_error'
        expect(parsed_body.error_description).to include('Email has already been taken')
      end

      it 'does not create a user' do
        expect(User.count).to eq(1)
      end

      it 'does not create a token' do
        expect(Devise::Api::Token.count).to eq(0)
      end

      it 'calls the before_sign_up callback only' do
        expect(Devise.api.config.before_sign_up).to have_received(:call).once
      end
    end
  end

  describe 'POST /users/tokens/sign_in' do
    context 'when the user confirmed' do
      let(:user) { create(:user, password: 'pass123456') }
      let(:params) { { email: user.email, password: 'pass123456' } }

      before do
        user.confirm

        allow(Devise.api.config.after_successful_sign_in).to receive(:call).and_call_original
        allow(Devise.api.config.before_sign_in).to receive(:call).and_call_original

        post sign_in_user_tokens_path, params: params, as: :json
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'returns a token' do
        expect(parsed_body.token).to be_present
        expect(parsed_body.refresh_token).to be_present
        expect(parsed_body.expires_in).to eq(1.hour.to_i)
        expect(parsed_body.token_type).to eq('Bearer')
        expect(parsed_body.resource_owner).to be_present
        expect(parsed_body.resource_owner.id).to eq(user.id)
        expect(parsed_body.resource_owner.email).to eq(user.email)
        expect(parsed_body.resource_owner.created_at.to_date).to eq user.created_at.to_date
        expect(parsed_body.resource_owner.updated_at.to_date).to eq user.updated_at.to_date
      end

      it 'trackable is incremented' do
        expect(User.last.sign_in_count).to eq(1)
        expect(User.last.current_sign_in_at).to be_present
        expect(User.last.last_sign_in_at).to be_present
        expect(User.last.current_sign_in_ip).to be_present
        expect(User.last.last_sign_in_ip).to be_present
      end

      it 'calls the after_successful_sign_in and before_sign_in callbacks' do
        expect(Devise.api.config.after_successful_sign_in).to have_received(:call).once
        expect(Devise.api.config.before_sign_in).to have_received(:call).once
      end
    end

    context 'when the user is not confirmed' do
      let(:user) { create(:user, password: 'pass123456') }
      let(:params) { { email: user.email, password: 'pass123456' } }

      before do
        allow(Devise.api.config.before_sign_in).to receive(:call).and_call_original

        post sign_in_user_tokens_path, params: params, as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'invalid_authentication'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.confirmable.unconfirmed')])
        expect(parsed_body.confirmable).to be_present
        expect(parsed_body.confirmable.confirmed).to eq false
        expect(parsed_body.confirmable.confirmation_sent_at.to_date).to eq user.confirmation_sent_at.to_date
      end

      it 'does not create a token' do
        expect(Devise::Api::Token.count).to eq(0)
      end

      it 'calls the before_sign_in callback only' do
        expect(Devise.api.config.before_sign_in).to have_received(:call).once
      end
    end

    context 'when the user is locked' do
      let(:user) { create(:user, password: 'pass123456') }
      let(:params) { { email: user.email, password: 'pass123456' } }

      before do
        user.lock_access!

        allow(Devise.api.config.before_sign_in).to receive(:call).and_call_original

        post sign_in_user_tokens_path, params: params, as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'invalid_authentication'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.lockable.locked')])
        expect(parsed_body.lockable).to be_present
        expect(parsed_body.lockable.locked).to eq true
        expect(parsed_body.lockable.max_attempts).to eq Devise.maximum_attempts
        expect(parsed_body.lockable.failed_attemps).to be_present
        expect(parsed_body.lockable.locked_at.to_date).to eq user.locked_at.to_date
      end

      it 'does not create a token' do
        expect(Devise::Api::Token.count).to eq(0)
      end

      it 'calls the before_sign_in callback only' do
        expect(Devise.api.config.before_sign_in).to have_received(:call).once
      end
    end

    context 'when the user is not found' do
      let(:params) { { email: 'invalid@mail.com', password: 'pass123456' } }

      before do
        allow(Devise.api.config.before_sign_in).to receive(:call).and_call_original

        post sign_in_user_tokens_path, params: params, as: :json
      end

      it 'returns http bad request' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'invalid_email'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.invalid_email')])
      end

      it 'does not create a token' do
        expect(Devise::Api::Token.count).to eq(0)
      end

      it 'calls the before_sign_in callback only' do
        expect(Devise.api.config.before_sign_in).to have_received(:call).once
      end
    end

    context 'when the password is invalid' do
      let(:user) { create(:user, password: 'pass123456') }
      let(:params) { { email: user.email, password: 'invalid' } }

      before do
        user.confirm

        allow(Devise.api.config.before_sign_in).to receive(:call).and_call_original

        post sign_in_user_tokens_path, params: params, as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'invalid_authentication'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.invalid_authentication')])
        expect(parsed_body.confirmable).to be_present
        expect(parsed_body.lockable).to be_present
        expect(parsed_body.lockable.locked).to eq false
        expect(parsed_body.lockable.max_attempts).to eq Devise.maximum_attempts
        expect(parsed_body.lockable.failed_attemps).to eq 1
      end

      it 'lockable is incremented' do
        expect(User.last.failed_attempts).to eq(1)
        expect(User.last.locked_at).to be_nil
      end

      it 'does not create a token' do
        expect(Devise::Api::Token.count).to eq(0)
      end

      it 'calls the before_sign_in callback only' do
        expect(Devise.api.config.before_sign_in).to have_received(:call).once
      end
    end
  end

  describe 'GET /users/tokens/info' do
    context 'when the token is valid and on the header' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

      before do
        get info_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the authenticated resource owner' do
        expect(parsed_body.id).to eq(user.id)
        expect(parsed_body.email).to eq(user.email)
        expect(parsed_body.created_at.to_date).to eq user.created_at.to_date
        expect(parsed_body.updated_at.to_date).to eq user.updated_at.to_date
      end
    end

    context 'when the token is valid and on the url param' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

      before do
        get info_user_tokens_path(access_token: devise_api_token.access_token), as: :json
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the authenticated resource owner' do
        expect(parsed_body.id).to eq(user.id)
        expect(parsed_body.email).to eq(user.email)
        expect(parsed_body.created_at.to_date).to eq user.created_at.to_date
        expect(parsed_body.updated_at.to_date).to eq user.updated_at.to_date
      end
    end

    context 'when the token is invalid and on the header' do
      let(:user) { create(:user) }
      let(:devise_api_token) { build(:devise_api_token, resource_owner: user) }

      before do
        get info_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
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
        get info_user_tokens_path(access_token: 'invalid'), as: :json
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
        get info_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
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
        get info_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
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

  describe 'POST /users/tokens/refresh' do
    context 'when the refresh token is valid and on the header' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

      before do
        allow(Devise.api.config.before_refresh).to receive(:call).and_call_original
        allow(Devise.api.config.after_successful_refresh).to receive(:call).and_call_original

        post refresh_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the new token' do
        expect(parsed_body.token).to be_present
        expect(parsed_body.refresh_token).to be_present
        expect(parsed_body.expires_in).to eq(1.hour.to_i)
        expect(parsed_body.token_type).to eq('Bearer')
        expect(parsed_body.resource_owner).to be_present
        expect(parsed_body.resource_owner.id).to eq(User.last.id)
        expect(parsed_body.resource_owner.email).to eq(user.email)
        expect(parsed_body.resource_owner.created_at).to be_present
        expect(parsed_body.resource_owner.updated_at).to be_present
      end

      it 'creates a new token' do
        expect(devise_api_token.refreshes.count).to eq(1)
      end

      it 'calls the before_refresh_token and after_successful_refresh callbacks' do
        expect(Devise.api.config.before_refresh).to have_received(:call).once
        expect(Devise.api.config.after_successful_refresh).to have_received(:call).once
      end
    end

    context 'when the refresh token is valid and on the url param' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

      before do
        allow(Devise.api.config.before_refresh).to receive(:call).and_call_original
        allow(Devise.api.config.after_successful_refresh).to receive(:call).and_call_original

        post refresh_user_tokens_path(access_token: devise_api_token.refresh_token), as: :json
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the new token' do
        expect(parsed_body.token).to be_present
        expect(parsed_body.refresh_token).to be_present
        expect(parsed_body.expires_in).to eq(1.hour.to_i)
        expect(parsed_body.token_type).to eq('Bearer')
        expect(parsed_body.resource_owner).to be_present
        expect(parsed_body.resource_owner.id).to eq(User.last.id)
        expect(parsed_body.resource_owner.email).to eq(user.email)
        expect(parsed_body.resource_owner.created_at).to be_present
        expect(parsed_body.resource_owner.updated_at).to be_present
      end

      it 'creates a new token' do
        expect(devise_api_token.refreshes.count).to eq(1)
      end

      it 'calls the before_refresh_token and after_successful_refresh callbacks' do
        expect(Devise.api.config.before_refresh).to have_received(:call).once
        expect(Devise.api.config.after_successful_refresh).to have_received(:call).once
      end
    end

    context 'when the refresh token is invalid and on the header' do
      let(:user) { create(:user) }
      let(:devise_api_token) { build(:devise_api_token, resource_owner: user) }

      before do
        post refresh_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'invalid_token'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.invalid_token')])
      end

      it 'does not refresh the token' do
        expect(devise_api_token.refreshes.count).to eq(0)
      end
    end

    context 'when the refresh token is invalid and on the url param' do
      let(:user) { create(:user) }
      let(:devise_api_token) { build(:devise_api_token, resource_owner: user) }

      before do
        post refresh_user_tokens_path(access_token: devise_api_token.refresh_token), as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'invalid_token'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.invalid_token')])
      end

      it 'does not refresh the token' do
        expect(devise_api_token.refreshes.count).to eq(0)
      end
    end

    context 'when the devise api token is expired' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, :refresh_token_expired, resource_owner: user) }

      before do
        post refresh_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'expired_token'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.expired_token')])
      end

      it 'does not refresh the token' do
        expect(devise_api_token.refreshes.count).to eq(0)
      end
    end

    context 'when the devise api token is revoked' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, :revoked, resource_owner: user) }

      before do
        post refresh_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response' do
        expect(parsed_body.error).to eq 'revoked_token'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.revoked_token')])
      end

      it 'does not refresh the token' do
        expect(devise_api_token.refreshes.count).to eq(0)
      end
    end
  end

  describe 'POST /users/tokens/revoke' do
    context 'when the access token is valid and on the header' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

      before do
        allow(Devise.api.config.before_revoke).to receive(:call).and_call_original
        allow(Devise.api.config.after_successful_revoke).to receive(:call).and_call_original

        post revoke_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http no content' do
        expect(response).to have_http_status(:no_content)
      end

      it 'returns an empty response' do
        expect(response.body).to be_empty
      end

      it 'revokes the token' do
        expect(devise_api_token.reload.revoked?).to be_truthy
      end

      it 'calls the before_revoke_token and after_successful_revoke callbacks' do
        expect(Devise.api.config.before_revoke).to have_received(:call).once
        expect(Devise.api.config.after_successful_revoke).to have_received(:call).once
      end
    end

    context 'when the access token is valid and on the url param' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, resource_owner: user) }

      before do
        post revoke_user_tokens_path(access_token: devise_api_token.access_token), as: :json
      end

      it 'returns http no content' do
        expect(response).to have_http_status(:no_content)
      end

      it 'returns an empty response' do
        expect(response.body).to be_empty
      end

      it 'revokes the token' do
        expect(devise_api_token.reload.revoked?).to be_truthy
      end
    end

    context 'when the access token is invalid and on the header' do
      let(:user) { create(:user) }
      let(:devise_api_token) { build(:devise_api_token, resource_owner: user) }

      before do
        post revoke_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http no content' do
        expect(response).to have_http_status(:no_content)
      end

      it 'returns an empty response' do
        expect(response.body).to be_empty
      end
    end

    context 'when the access token is invalid and on the url param' do
      let(:user) { create(:user) }
      let(:devise_api_token) { build(:devise_api_token, resource_owner: user) }

      before do
        post revoke_user_tokens_path(access_token: devise_api_token.access_token), as: :json
      end

      it 'returns http no content' do
        expect(response).to have_http_status(:no_content)
      end

      it 'returns an empty response' do
        expect(response.body).to be_empty
      end
    end

    context 'when the access token is expired' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, :access_token_expired, resource_owner: user) }

      before do
        post revoke_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http no content' do
        expect(response).to have_http_status(:no_content)
      end

      it 'returns an empty response' do
        expect(response.body).to be_empty
      end
    end

    context 'when the access token is revoked' do
      let(:user) { create(:user) }
      let(:devise_api_token) { create(:devise_api_token, :revoked, resource_owner: user) }

      before do
        post revoke_user_tokens_path, headers: authentication_headers_for(user, devise_api_token), as: :json
      end

      it 'returns http no content' do
        expect(response).to have_http_status(:no_content)
      end

      it 'returns an empty response' do
        expect(response.body).to be_empty
      end
    end
  end
end
