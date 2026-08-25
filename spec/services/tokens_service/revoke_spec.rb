# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::TokensService::Revoke do
  it 'inherits from Devise::Api::BaseService' do
    expect(described_class).to be < Devise::Api::BaseService
  end

  describe '#call' do
    let(:result) { described_class.new(devise_api_token: devise_api_token).call }

    context 'when the token is blank' do
      let(:devise_api_token) { nil }

      it 'returns a success without a token' do
        expect(result).to be_success
        expect(result.success).to be_nil
      end
    end

    context 'when the token is already revoked' do
      let(:devise_api_token) { create(:devise_api_token, :revoked) }

      it 'returns a success without updating the token' do
        revoked_at = devise_api_token.revoked_at

        expect(result).to be_success
        expect(devise_api_token.reload.revoked_at).to eq(revoked_at)
      end
    end

    context 'when the token is already expired' do
      let(:devise_api_token) { create(:devise_api_token, :access_token_expired) }

      it 'returns a success without revoking the token' do
        expect(result).to be_success
        expect(devise_api_token.reload.revoked_at).to be_nil
      end
    end

    context 'when the token is revokable' do
      let(:devise_api_token) { create(:devise_api_token) }

      it 'returns a success and revokes the token' do
        expect(result).to be_success
        expect(devise_api_token.reload.revoked?).to eq true
      end
    end

    context 'when the update fails' do
      let(:devise_api_token) { create(:devise_api_token) }

      before do
        allow(devise_api_token).to receive(:update).and_return(false)
      end

      it 'returns a failure with the token' do
        expect(result).to be_failure
        expect(result.failure).to eq(error: :devise_api_token_revoke_error, record: devise_api_token)
      end
    end
  end
end
