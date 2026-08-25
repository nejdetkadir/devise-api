# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::TokensService::Refresh do
  it 'inherits from Devise::Api::BaseService' do
    expect(described_class).to be < Devise::Api::BaseService
  end

  describe '#call' do
    let(:result) { described_class.new(devise_api_token: devise_api_token).call }

    context 'when the refresh token is expired' do
      let(:devise_api_token) { create(:devise_api_token, :refresh_token_expired) }

      it 'returns a failure' do
        expect(result).to be_failure
        expect(result.failure).to eq(error: :expired_refresh_token)
      end

      it 'does not create a token' do
        result

        expect(Devise::Api::Token.count).to eq(1)
      end
    end

    context 'when the refresh token is valid' do
      let(:devise_api_token) { create(:devise_api_token) }

      it 'returns a success with a new token' do
        expect(result).to be_success
        expect(result.success).to be_persisted
        expect(result.success.previous_refresh_token).to eq(devise_api_token.refresh_token)
        expect(result.success.resource_owner).to eq(devise_api_token.resource_owner)
      end

      it 'creates a new token' do
        result

        expect(Devise::Api::Token.count).to eq(2)
      end
    end

    context 'when the token creation fails' do
      let(:devise_api_token) { create(:devise_api_token) }

      before do
        allow(Devise.api.config.access_token).to receive(:expires_in).and_return(nil)
      end

      it 'returns a failure' do
        expect(result).to be_failure
        expect(result.failure[:error]).to eq(:devise_api_token_create_error)
      end
    end
  end
end
