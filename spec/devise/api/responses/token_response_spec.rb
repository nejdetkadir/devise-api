# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::Responses::TokenResponse do
  context 'action types' do
    let(:resource_owner) { double('resource_owner') }
    let(:token) { double('token', resource_owner: resource_owner) }

    it 'has a list of actions' do
      expect(described_class::ACTIONS).to eq(%i[sign_in sign_up refresh revoke info])
    end

    it 'has a method for each action' do
      expect(described_class.new(nil, token: token, action: :sign_in)).to respond_to(:sign_in_action?)
      expect(described_class.new(nil, token: token, action: :sign_up)).to respond_to(:sign_up_action?)
      expect(described_class.new(nil, token: token, action: :refresh)).to respond_to(:refresh_action?)
      expect(described_class.new(nil, token: token, action: :revoke)).to respond_to(:revoke_action?)
      expect(described_class.new(nil, token: token, action: :info)).to respond_to(:info_action?)
    end
  end

  context 'sign in' do
    let(:resource_owner) do
      double('resource_owner',
             id: 1,
             email: 'test@development.com',
             created_at: Time.now,
             updated_at: Time.now)
    end
    let(:token) do
      double('token', resource_owner: resource_owner, access_token: 'access_token', refresh_token: 'refresh_token',
                      expires_in: 3600)
    end
    let(:token_response) { described_class.new(nil, token: token, action: :sign_in) }

    it 'returns the correct body' do
      expect(token_response.body).to eq({
                                          token: 'access_token',
                                          refresh_token: 'refresh_token',
                                          expires_in: 3600,
                                          token_type: 'Bearer',
                                          resource_owner: {
                                            id: 1,
                                            email: 'test@development.com',
                                            created_at: resource_owner.created_at,
                                            updated_at: resource_owner.updated_at
                                          }
                                        })
    end

    it 'returns the correct status' do
      expect(token_response.status).to eq(:ok)
    end
  end

  context 'sign up' do
    let(:supported_devise_modules) { double('supported_devise_modules', confirmable?: true) }
    let(:resource_owner_class) { double('resource_owner_class', supported_devise_modules: supported_devise_modules) }
    let(:resource_owner) do
      double('resource_owner',
             id: 1,
             email: 'test@development.com',
             created_at: Time.now,
             updated_at: Time.now,
             class: resource_owner_class,
             confirmed?: true)
    end
    let(:token) do
      double('token', resource_owner: resource_owner, access_token: 'access_token', refresh_token: 'refresh_token',
                      expires_in: 3600)
    end
    let(:token_response) { described_class.new(nil, token: token, action: :sign_up) }

    it 'returns the correct body' do
      expect(token_response.body).to eq({
                                          token: 'access_token',
                                          refresh_token: 'refresh_token',
                                          expires_in: 3600,
                                          token_type: 'Bearer',
                                          resource_owner: {
                                            id: 1,
                                            email: 'test@development.com',
                                            created_at: resource_owner.created_at,
                                            updated_at: resource_owner.updated_at
                                          },
                                          confirmable: {
                                            confirmed: true
                                          }
                                        })
    end

    it 'returns the correct status' do
      expect(token_response.status).to eq(:created)
    end
  end

  context 'refresh' do
    let(:resource_owner) do
      double('resource_owner',
             id: 1,
             email: 'test@development.com',
             created_at: Time.now,
             updated_at: Time.now)
    end
    let(:token) do
      double('token', resource_owner: resource_owner, access_token: 'access_token', refresh_token: 'refresh_token',
                      expires_in: 3600)
    end
    let(:token_response) { described_class.new(nil, token: token, action: :refresh) }

    it 'returns the correct body' do
      expect(token_response.body).to eq({
                                          token: 'access_token',
                                          refresh_token: 'refresh_token',
                                          expires_in: 3600,
                                          token_type: 'Bearer',
                                          resource_owner: {
                                            id: 1,
                                            email: 'test@development.com',
                                            created_at: resource_owner.created_at,
                                            updated_at: resource_owner.updated_at
                                          }
                                        })
    end

    it 'returns the correct status' do
      expect(token_response.status).to eq(:ok)
    end
  end

  context 'revoke' do
    let(:resource_owner) do
      double('resource_owner',
             id: 1,
             email: 'test@development.com',
             created_at: Time.now,
             updated_at: Time.now)
    end
    let(:token) do
      double('token', resource_owner: resource_owner, access_token: 'access_token', refresh_token: 'refresh_token',
                      expires_in: 3600)
    end
    let(:token_response) { described_class.new(nil, token: token, action: :revoke) }

    it 'returns the correct body' do
      expect(token_response.body).to eq({})
    end

    it 'returns the correct status' do
      expect(token_response.status).to eq(:no_content)
    end
  end

  context 'info' do
    let(:resource_owner) do
      double('resource_owner',
             id: 1,
             email: 'test@development.com',
             created_at: Time.now,
             updated_at: Time.now)
    end
    let(:token) do
      double('token', resource_owner: resource_owner, access_token: 'access_token', refresh_token: 'refresh_token',
                      expires_in: 3600)
    end
    let(:token_response) { described_class.new(nil, token: token, action: :info) }

    it 'returns the correct body' do
      expect(token_response.body).to eq({
                                          id: 1,
                                          email: 'test@development.com',
                                          created_at: resource_owner.created_at,
                                          updated_at: resource_owner.updated_at
                                        })
    end

    it 'returns the correct status' do
      expect(token_response.status).to eq(:ok)
    end
  end
end
