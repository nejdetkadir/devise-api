# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::Configuration do
  let(:config) { described_class.new }

  it 'extens from dry-configurable' do
    expect(described_class).to be < Dry::Configurable
  end

  context 'default settings' do
    context 'access_token' do
      it 'expires_in is 1.hour' do
        expect(config.access_token.expires_in).to eq 1.hour
      end

      it 'expires_in_infinite is false' do
        expect(config.access_token.expires_in_infinite.call).to eq false
      end

      it 'generator returns a token string with using Devise.friendly_token' do
        allow(Devise).to receive(:friendly_token).with(60).and_return('token')
        expect(config.access_token.generator.call).to eq 'token'
        expect(Devise).to have_received(:friendly_token).with(60)
        expect(config.access_token.generator).to be_a Proc
      end
    end

    context 'refresh_token' do
      it 'enabled is true' do
        expect(config.refresh_token.enabled).to eq true
      end

      it 'expires_in is 1.week' do
        expect(config.refresh_token.expires_in).to eq 1.week
      end

      it 'expires_in_infinite is false' do
        expect(config.refresh_token.expires_in_infinite.call).to eq false
      end

      it 'generator returns a token string with using Devise.friendly_token' do
        allow(Devise).to receive(:friendly_token).with(60).and_return('token')
        expect(config.refresh_token.generator.call).to eq 'token'
        expect(Devise).to have_received(:friendly_token).with(60)
        expect(config.refresh_token.generator).to be_a Proc
      end
    end

    context 'sign_up' do
      it 'enabled is true' do
        expect(config.sign_up.enabled).to eq true
      end
    end

    context 'authorization' do
      it 'key is Authorization' do
        expect(config.authorization.key).to eq 'Authorization'
      end

      it 'scheme is Bearer' do
        expect(config.authorization.scheme).to eq 'Bearer'
      end

      it 'location is both' do
        expect(config.authorization.location).to eq :both
      end

      it 'params_key is access_token' do
        expect(config.authorization.params_key).to eq 'access_token'
      end
    end

    context 'base classes' do
      it 'base_token_model is Devise::Api::Token' do
        expect(config.base_token_model).to eq 'Devise::Api::Token'
      end

      it 'base_controller is DeviseController' do
        expect(config.base_controller).to eq '::DeviseController'
      end
    end

    context 'after callbacks' do
      it 'after_successful_sign_in is a proc' do
        expect(config.after_successful_sign_in).to be_a Proc
      end

      it 'after_successful_sign_up is a proc' do
        expect(config.after_successful_sign_up).to be_a Proc
      end

      it 'after_successful_refresh is a proc' do
        expect(config.after_successful_refresh).to be_a Proc
      end

      it 'after_successful_revoke is a proc' do
        expect(config.after_successful_revoke).to be_a Proc
      end
    end

    context 'before callbacks' do
      it 'before_sign_in is a proc' do
        expect(config.before_sign_in).to be_a Proc
      end

      it 'before_sign_up is a proc' do
        expect(config.before_sign_up).to be_a Proc
      end

      it 'before_refresh is a proc' do
        expect(config.before_refresh).to be_a Proc
      end

      it 'before_revoke is a proc' do
        expect(config.before_revoke).to be_a Proc
      end
    end
  end
end
