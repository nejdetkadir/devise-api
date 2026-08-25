# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::Controllers::Helpers do
  let(:host_class) do
    Class.new do
      include Devise::Api::Controllers::Helpers

      attr_accessor :request, :params
    end
  end
  let(:host) { host_class.new }

  describe '#current_devise_api_refresh_token' do
    context 'when the extracted token matches a refresh token' do
      let(:devise_api_token) { create(:devise_api_token) }

      before do
        allow(host).to receive(:find_devise_api_token).and_return(devise_api_token.refresh_token)
      end

      it 'returns the token record' do
        expect(host.current_devise_api_refresh_token).to eq(devise_api_token)
      end
    end

    context 'when no token can be extracted' do
      before do
        allow(host).to receive(:find_devise_api_token).and_return(nil)
      end

      it 'returns nil' do
        expect(host.current_devise_api_refresh_token).to be_nil
      end
    end
  end

  describe '#current_devise_api_user' do
    context 'when the extracted token matches an access token' do
      let(:devise_api_token) { create(:devise_api_token) }

      before do
        allow(host).to receive(:find_devise_api_token).and_return(devise_api_token.access_token)
      end

      it 'returns the resource owner' do
        expect(host.current_devise_api_user).to eq(devise_api_token.resource_owner)
      end
    end

    context 'when no token can be extracted' do
      before do
        allow(host).to receive(:find_devise_api_token).and_return(nil)
      end

      it 'returns nil' do
        expect(host.current_devise_api_user).to be_nil
      end
    end
  end

  describe '#extract_devise_api_token_from_headers' do
    context 'when stripping the authorization scheme raises an error' do
      let(:token) { double('token', blank?: false) }

      before do
        host.request = double('request', headers: { 'Authorization' => token })

        allow(token).to receive(:gsub).and_raise(StandardError)
      end

      it 'returns the raw token' do
        expect(host.send(:extract_devise_api_token_from_headers)).to eq(token)
      end
    end
  end

  describe '#find_devise_api_token' do
    context 'when the authorization location is invalid' do
      before do
        allow(Devise.api.config.authorization).to receive(:location).and_return(:invalid)
      end

      it 'raises an ArgumentError' do
        expect { host.send(:find_devise_api_token) }
          .to raise_error(ArgumentError, 'Invalid authorization location, must be :header, :params or :both')
      end
    end
  end
end
