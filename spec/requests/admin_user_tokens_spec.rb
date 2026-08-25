# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::TokensController, type: :request do
  describe 'POST /admin_users/tokens/sign_up' do
    context 'when the admin user is valid' do
      let(:params) { attributes_for(:admin_user) }

      before do
        post sign_up_admin_user_tokens_path, params: params, as: :json
      end

      it 'returns http success' do
        expect(response).to have_http_status(:created)
      end

      it 'returns a token' do
        expect(parsed_body.token).to be_present
        expect(parsed_body.refresh_token).to be_present
        expect(parsed_body.expires_in).to eq(1.hour.to_i)
        expect(parsed_body.token_type).to eq('Bearer')
        expect(parsed_body.resource_owner.id).to eq(AdminUser.last.id)
        expect(parsed_body.resource_owner.email).to eq(params[:email])
      end

      it 'does not return confirmable info' do
        expect(parsed_body.confirmable).to be_nil
      end

      it 'creates an admin user' do
        expect(AdminUser.count).to eq(1)
        expect(AdminUser.last.email).to eq(params[:email])
      end

      it 'creates a token' do
        expect(Devise::Api::Token.count).to eq(1)
        expect(Devise::Api::Token.last.resource_owner_type).to eq('AdminUser')
      end
    end
  end

  describe 'POST /admin_users/tokens/sign_in' do
    context 'when the credentials are valid' do
      let(:admin_user) { create(:admin_user, password: 'pass123456') }
      let(:params) { { email: admin_user.email, password: 'pass123456' } }

      before do
        post sign_in_admin_user_tokens_path, params: params, as: :json
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'returns a token' do
        expect(parsed_body.token).to be_present
        expect(parsed_body.resource_owner.id).to eq(admin_user.id)
        expect(parsed_body.resource_owner.email).to eq(admin_user.email)
      end
    end

    context 'when the password is invalid' do
      let(:admin_user) { create(:admin_user) }
      let(:params) { { email: admin_user.email, password: 'wrong password' } }

      before do
        post sign_in_admin_user_tokens_path, params: params, as: :json
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error response without lockable and confirmable info' do
        expect(parsed_body.error).to eq 'invalid_authentication'
        expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.invalid_authentication')])
        expect(parsed_body.lockable).to be_nil
        expect(parsed_body.confirmable).to be_nil
      end

      it 'does not create a token' do
        expect(Devise::Api::Token.count).to eq(0)
      end
    end
  end
end
