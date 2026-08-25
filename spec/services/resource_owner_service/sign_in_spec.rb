# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::ResourceOwnerService::SignIn do
  it 'inherits from Devise::Api::BaseService' do
    expect(described_class).to be < Devise::Api::BaseService
  end

  describe '#call' do
    context 'when the authentication fails' do
      let(:user) { create(:user) }
      let(:result) do
        described_class.new(params: { email: user.email, password: 'wrong password' }, resource_class: User).call
      end

      it 'returns a failure' do
        expect(result).to be_failure
        expect(result.failure).to eq(error: :invalid_authentication, record: user)
      end

      it 'does not create a token' do
        result

        expect(Devise::Api::Token.count).to eq(0)
      end
    end

    context 'when the resource owner is lockable' do
      let(:user) { create(:user, password: 'pass123456') }
      let(:result) do
        described_class.new(params: { email: user.email, password: 'pass123456' }, resource_class: User).call
      end

      before do
        user.confirm
        user.update(failed_attempts: 2)
      end

      it 'returns a success with a token' do
        expect(result).to be_success
        expect(result.success.resource_owner).to eq(user)
      end

      it 'resets the failed attempts' do
        result

        expect(user.reload.failed_attempts).to eq(0)
      end
    end

    context 'when the resource owner is not lockable' do
      let(:admin_user) { create(:admin_user, password: 'pass123456') }
      let(:result) do
        described_class.new(params: { email: admin_user.email, password: 'pass123456' },
                            resource_class: AdminUser).call
      end

      it 'returns a success with a token' do
        expect(result).to be_success
        expect(result.success.resource_owner).to eq(admin_user)
      end
    end
  end
end
