# frozen_string_literal: true

require 'spec_helper'

# Covers the account-enumeration hardening flags: paranoid (SEC-5) and
# error_response.verbose_account_state (SEC-7).
RSpec.describe Devise::Api::TokensController, type: :request do
  describe 'POST /users/tokens/sign_in' do
    context 'when paranoid mode is enabled' do
      around do |example|
        original = Devise.api.config.paranoid
        Devise.api.config.paranoid = true
        example.run
      ensure
        Devise.api.config.paranoid = original
      end

      context 'and the account does not exist' do
        before do
          post sign_in_user_tokens_path, params: { email: 'unknown@development.com', password: 'pass123456' },
                                         as: :json
        end

        it 'returns http unauthorized instead of bad request' do
          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns the generic invalid authentication error' do
          expect(parsed_body.error).to eq 'invalid_authentication'
          expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.invalid_authentication')])
        end
      end

      context 'and the password is wrong' do
        let(:user) { create(:user, password: 'pass123456') }

        before do
          user.confirm

          post sign_in_user_tokens_path, params: { email: user.email, password: 'wrong password' }, as: :json
        end

        it 'returns the same response shape as a missing account' do
          expect(response).to have_http_status(:unauthorized)
          expect(parsed_body.error).to eq 'invalid_authentication'
          expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.invalid_authentication')])
        end

        it 'does not expose lockable or confirmable state' do
          expect(parsed_body.lockable).to be_nil
          expect(parsed_body.confirmable).to be_nil
        end
      end

      context 'and the account is locked' do
        let(:user) { create(:user, password: 'pass123456') }

        before do
          user.confirm
          user.lock_access!

          post sign_in_user_tokens_path, params: { email: user.email, password: 'pass123456' }, as: :json
        end

        it 'returns the generic invalid authentication error without account state' do
          expect(response).to have_http_status(:unauthorized)
          expect(parsed_body.error).to eq 'invalid_authentication'
          expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.invalid_authentication')])
          expect(parsed_body.lockable).to be_nil
          expect(parsed_body.confirmable).to be_nil
        end
      end
    end

    context 'when verbose account state is disabled' do
      around do |example|
        original = Devise.api.config.error_response.verbose_account_state
        Devise.api.config.error_response.verbose_account_state = false
        example.run
      ensure
        Devise.api.config.error_response.verbose_account_state = original
      end

      context 'and the password is wrong' do
        let(:user) { create(:user, password: 'pass123456') }

        before do
          user.confirm

          post sign_in_user_tokens_path, params: { email: user.email, password: 'wrong password' }, as: :json
        end

        it 'omits the lockable and confirmable blocks' do
          expect(response).to have_http_status(:unauthorized)
          expect(parsed_body.error).to eq 'invalid_authentication'
          expect(parsed_body.lockable).to be_nil
          expect(parsed_body.confirmable).to be_nil
        end
      end

      context 'and the account is locked' do
        let(:user) { create(:user, password: 'pass123456') }

        before do
          user.confirm
          user.lock_access!

          post sign_in_user_tokens_path, params: { email: user.email, password: 'pass123456' }, as: :json
        end

        it 'keeps the locked error description but omits the lockable metadata' do
          expect(response).to have_http_status(:unauthorized)
          expect(parsed_body.error).to eq 'invalid_authentication'
          expect(parsed_body.error_description).to eq([I18n.t('devise.api.error_response.lockable.locked')])
          expect(parsed_body.lockable).to be_nil
          expect(parsed_body.confirmable).to be_nil
        end
      end
    end
  end
end
