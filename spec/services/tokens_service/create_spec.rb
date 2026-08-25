# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::TokensService::Create do
  it 'inherits from Devise::Api::BaseService' do
    expect(described_class).to be < Devise::Api::BaseService
  end

  describe '#call' do
    let(:result) { described_class.new(resource_owner: resource_owner).call }

    context 'when the resource owner does not respond to access_tokens' do
      let(:resource_owner) { nil }

      it 'returns a failure' do
        expect(result).to be_failure
        expect(result.failure).to eq(error: :invalid_resource_owner)
      end

      it 'does not create a token' do
        result

        expect(Devise::Api::Token.count).to eq(0)
      end
    end

    context 'when the resource owner is valid' do
      let(:resource_owner) { create(:user) }

      it 'returns a success with a persisted token' do
        expect(result).to be_success
        expect(result.success).to be_persisted
        expect(result.success.resource_owner).to eq(resource_owner)
        expect(result.success.expires_in).to eq(Devise.api.config.access_token.expires_in.to_i)
        expect(result.success.previous_refresh_token).to be_nil
      end
    end

    context 'when a previous refresh token is given' do
      let(:resource_owner) { create(:user) }
      let(:result) do
        described_class.new(resource_owner: resource_owner, previous_refresh_token: 'previous token').call
      end

      it 'returns a success with the previous refresh token set' do
        expect(result).to be_success
        expect(result.success.previous_refresh_token).to eq('previous token')
      end
    end

    context 'when the token cannot be saved' do
      let(:resource_owner) { create(:user) }

      before do
        allow(Devise.api.config.access_token).to receive(:expires_in).and_return(nil)
      end

      it 'returns a failure with the invalid record' do
        expect(result).to be_failure
        expect(result.failure[:error]).to eq(:devise_api_token_create_error)
        expect(result.failure[:record].errors).to be_present
      end

      it 'does not create a token' do
        result

        expect(Devise::Api::Token.count).to eq(0)
      end
    end
  end
end
