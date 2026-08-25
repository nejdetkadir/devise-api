# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::ResourceOwnerService::SignUp do
  it 'inherits from Devise::Api::BaseService' do
    expect(described_class).to be < Devise::Api::BaseService
  end

  describe '#call' do
    let(:result) { described_class.new(params: params, resource_class: User).call }

    context 'when the resource owner is invalid' do
      let(:user) { create(:user) }
      let(:params) { attributes_for(:user, email: user.email) }

      it 'returns a failure with the invalid record' do
        expect(result).to be_failure
        expect(result.failure[:error]).to eq(:resource_owner_create_error)
        expect(result.failure[:record].errors).to be_present
      end

      it 'does not create a resource owner' do
        result

        expect(User.count).to eq(1)
      end
    end

    context 'when the resource owner is valid' do
      let(:params) { attributes_for(:user) }

      it 'returns a success with a token' do
        expect(result).to be_success
        expect(result.success).to be_persisted
        expect(result.success.resource_owner.email).to eq(params[:email])
      end

      it 'creates the resource owner and the token' do
        result

        expect(User.count).to eq(1)
        expect(Devise::Api::Token.count).to eq(1)
      end
    end

    context 'when the token creation fails' do
      let(:params) { attributes_for(:user) }

      before do
        allow(Devise.api.config.access_token).to receive(:expires_in).and_return(nil)
      end

      it 'returns a failure' do
        expect(result).to be_failure
        expect(result.failure[:error]).to eq(:devise_api_token_create_error)
      end

      it 'rolls back the resource owner creation' do
        result

        expect(User.count).to eq(0)
      end
    end
  end
end
