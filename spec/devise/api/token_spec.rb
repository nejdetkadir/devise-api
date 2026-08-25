# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::Token do
  describe '#active?' do
    context 'when the token is not revoked and not expired' do
      let(:devise_api_token) { create(:devise_api_token) }

      it 'returns true' do
        expect(devise_api_token.active?).to eq true
        expect(devise_api_token.inactive?).to eq false
      end
    end

    context 'when the token is revoked' do
      let(:devise_api_token) { create(:devise_api_token, :revoked) }

      it 'returns false' do
        expect(devise_api_token.active?).to eq false
        expect(devise_api_token.inactive?).to eq true
      end
    end

    context 'when the token is expired' do
      let(:devise_api_token) { create(:devise_api_token, :access_token_expired) }

      it 'returns false' do
        expect(devise_api_token.active?).to eq false
        expect(devise_api_token.inactive?).to eq true
      end
    end
  end

  describe '#expired?' do
    context 'when the access token lifetime has passed' do
      let(:devise_api_token) { create(:devise_api_token, :access_token_expired) }

      it 'returns true' do
        expect(devise_api_token.expired?).to eq true
      end
    end

    context 'when the access token lifetime has not passed' do
      let(:devise_api_token) { create(:devise_api_token) }

      it 'returns false' do
        expect(devise_api_token.expired?).to eq false
      end
    end

    context 'when the access token lifetime is infinite' do
      let(:devise_api_token) { create(:devise_api_token, :access_token_expired) }

      before do
        allow(Devise.api.config.access_token).to receive(:expires_in_infinite)
          .and_return(proc { |_resource_owner| true })
      end

      it 'returns false' do
        expect(devise_api_token.expired?).to eq false
      end
    end
  end

  describe '#refresh_token_expired?' do
    context 'when the refresh token lifetime has passed' do
      let(:devise_api_token) { create(:devise_api_token, :refresh_token_expired) }

      it 'returns true' do
        expect(devise_api_token.refresh_token_expired?).to eq true
      end
    end

    context 'when the refresh token lifetime has not passed' do
      let(:devise_api_token) { create(:devise_api_token) }

      it 'returns false' do
        expect(devise_api_token.refresh_token_expired?).to eq false
      end
    end

    context 'when the refresh token lifetime is infinite' do
      let(:devise_api_token) { create(:devise_api_token, :refresh_token_expired) }

      before do
        allow(Devise.api.config.refresh_token).to receive(:expires_in_infinite)
          .and_return(proc { |_resource_owner| true })
      end

      it 'returns false' do
        expect(devise_api_token.refresh_token_expired?).to eq false
      end
    end
  end

  describe '#revoke!' do
    context 'when the token is not revoked' do
      let(:devise_api_token) { create(:devise_api_token) }

      it 'stamps revoked_at' do
        expect(devise_api_token.revoke!).to eq devise_api_token
        expect(devise_api_token.reload.revoked?).to eq true
      end
    end

    context 'when the token is already revoked' do
      let(:devise_api_token) { create(:devise_api_token, :revoked) }

      it 'keeps the original revoked_at' do
        original_revoked_at = devise_api_token.revoked_at

        devise_api_token.revoke!

        expect(devise_api_token.reload.revoked_at).to be_within(1.second).of(original_revoked_at)
      end
    end
  end

  describe '#revoke_family!' do
    let(:user) { create(:user) }
    let!(:root_token) { create(:devise_api_token, resource_owner: user) }
    let!(:middle_token) do
      create(:devise_api_token, resource_owner: user, previous_refresh_token: root_token.refresh_token)
    end
    let!(:leaf_token) do
      create(:devise_api_token, resource_owner: user, previous_refresh_token: middle_token.refresh_token)
    end
    let!(:unrelated_token) { create(:devise_api_token, resource_owner: user) }

    it 'revokes the whole refresh chain from any member' do
      middle_token.revoke_family!

      expect(root_token.reload.revoked?).to eq true
      expect(middle_token.reload.revoked?).to eq true
      expect(leaf_token.reload.revoked?).to eq true
    end

    it 'does not touch tokens outside the family' do
      middle_token.revoke_family!

      expect(unrelated_token.reload.revoked?).to eq false
    end
  end

  describe 'database uniqueness of token secrets' do
    let(:devise_api_token) { create(:devise_api_token) }

    it 'rejects a duplicate access token even when validations are bypassed' do
      duplicate = build(:devise_api_token, resource_owner: devise_api_token.resource_owner,
                                           access_token: devise_api_token.access_token)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'rejects a duplicate refresh token even when validations are bypassed' do
      duplicate = build(:devise_api_token, resource_owner: devise_api_token.resource_owner,
                                           refresh_token: devise_api_token.refresh_token)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'secret redaction' do
    let(:devise_api_token) { create(:devise_api_token) }

    it 'filters token secrets out of #inspect' do
      expect(devise_api_token.inspect).to include('[FILTERED]')
      expect(devise_api_token.inspect).not_to include(devise_api_token.access_token)
      expect(devise_api_token.inspect).not_to include(devise_api_token.refresh_token)
    end
  end

  describe '.generate_uniq_access_token' do
    context 'when the first generated token is already taken' do
      let(:user) { create(:user) }
      let(:existing_devise_api_token) { create(:devise_api_token) }
      let(:generator) { double }

      before do
        allow(generator).to receive(:call).and_return(existing_devise_api_token.access_token, 'uniq access token')
        allow(Devise.api.config.access_token).to receive(:generator).and_return(generator)
      end

      it 'retries until the token is uniq' do
        expect(described_class.generate_uniq_access_token(user)).to eq('uniq access token')
        expect(generator).to have_received(:call).twice
      end
    end
  end

  describe '.generate_uniq_refresh_token' do
    context 'when the first generated token is already taken' do
      let(:user) { create(:user) }
      let(:existing_devise_api_token) { create(:devise_api_token) }
      let(:generator) { double }

      before do
        allow(generator).to receive(:call).and_return(existing_devise_api_token.refresh_token, 'uniq refresh token')
        allow(Devise.api.config.refresh_token).to receive(:generator).and_return(generator)
      end

      it 'retries until the token is uniq' do
        expect(described_class.generate_uniq_refresh_token(user)).to eq('uniq refresh token')
        expect(generator).to have_received(:call).twice
      end
    end

    context 'when refresh tokens are disabled' do
      let(:user) { create(:user) }

      before do
        allow(Devise.api.config.refresh_token).to receive(:enabled).and_return(false)
      end

      it 'returns nil' do
        expect(described_class.generate_uniq_refresh_token(user)).to be_nil
      end
    end
  end

  describe 'validations' do
    context 'when refresh tokens are enabled' do
      let(:devise_api_token) { build(:devise_api_token, refresh_token: nil) }

      it 'requires a refresh token' do
        expect(devise_api_token.valid?).to eq false
        expect(devise_api_token.errors[:refresh_token]).to be_present
      end
    end

    context 'when refresh tokens are disabled' do
      let(:devise_api_token) { build(:devise_api_token, refresh_token: nil) }

      before do
        allow(Devise.api.config.refresh_token).to receive(:enabled).and_return(false)
      end

      it 'does not require a refresh token' do
        expect(devise_api_token.valid?).to eq true
      end
    end

    context 'when the access token lifetime is infinite' do
      let(:devise_api_token) { build(:devise_api_token, expires_in: nil) }

      before do
        allow(Devise.api.config.access_token).to receive(:expires_in_infinite)
          .and_return(proc { |_resource_owner| true })
      end

      it 'does not require an expires_in' do
        expect(devise_api_token.valid?).to eq true
      end
    end

    context 'when the access token lifetime is not infinite' do
      let(:devise_api_token) { build(:devise_api_token, expires_in: nil) }

      it 'requires an expires_in' do
        expect(devise_api_token.valid?).to eq false
        expect(devise_api_token.errors[:expires_in]).to be_present
      end
    end
  end
end
