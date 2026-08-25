# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::ResourceOwnerService::Authenticate do
  it 'inherits from Devise::Api::BaseService' do
    expect(described_class).to be < Devise::Api::BaseService
  end

  describe '#call' do
    let(:result) { described_class.new(params: params, resource_class: User).call }

    context 'when no resource owner matches the authentication keys' do
      let(:params) { { email: 'unknown@development.com', password: 'pass123456' } }

      it 'returns a failure' do
        expect(result).to be_failure
        expect(result.failure).to eq(error: :invalid_email, record: nil)
      end
    end

    context 'when no resource owner matches non-email authentication keys' do
      let(:params) { { name: 'unknown', password: 'pass123456' } }

      before do
        allow(User).to receive(:authentication_keys).and_return([:name])
      end

      it 'returns a generic invalid login failure instead of invalid email' do
        expect(result).to be_failure
        expect(result.failure).to eq(error: :invalid_login, record: nil)
      end
    end

    context 'when paranoid mode is enabled and no resource owner matches' do
      let(:params) { { email: 'unknown@development.com', password: 'pass123456' } }

      around do |example|
        original = Devise.api.config.paranoid
        Devise.api.config.paranoid = true
        example.run
      ensure
        Devise.api.config.paranoid = original
      end

      it 'returns the same failure as a wrong password' do
        expect(result).to be_failure
        expect(result.failure).to eq(error: :invalid_authentication, record: nil)
      end
    end

    context 'when the password is wrong' do
      let(:user) { create(:user) }
      let(:params) { { email: user.email, password: 'wrong password' } }

      before do
        user.confirm
      end

      it 'returns a failure with the resource owner' do
        expect(result).to be_failure
        expect(result.failure).to eq(error: :invalid_authentication, record: user)
      end
    end

    context 'when the resource owner is not active for authentication' do
      let(:user) { create(:user, password: 'pass123456') }
      let(:params) { { email: user.email, password: 'pass123456' } }

      before do
        user.confirm
        user.lock_access!
      end

      it 'returns a failure with the resource owner' do
        expect(result).to be_failure
        expect(result.failure).to eq(error: :invalid_authentication, record: user)
      end
    end

    context 'when the credentials are valid' do
      let(:user) { create(:user, password: 'pass123456') }
      let(:params) { { email: user.email, password: 'pass123456' } }

      before do
        user.confirm
      end

      it 'returns a success with the resource owner' do
        expect(result).to be_success
        expect(result.success).to eq(user)
      end
    end
  end
end
