# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::Responses::TokenResponse do
  let(:resource_owner) do
    FactoryBot.build(
      :user,
      id: 1,
      email: 'test@development.com',
      created_at: Time.now,
      updated_at: Time.now
    )
  end
  let(:token) do
    FactoryBot.build(
      :devise_api_token,
      resource_owner: resource_owner,
      access_token: 'access_token',
      refresh_token: 'refresh_token',
      expires_in: 3600
    )
  end

  context 'action types' do
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
                                          }.stringify_keys
                                        })
    end

    it 'returns the correct status' do
      expect(token_response.status).to eq(:ok)
    end
  end

  context 'sign up' do
    let(:token_response) { described_class.new(nil, token: token, action: :sign_up) }

    it 'returns the correct body' do
      allow(resource_owner).to receive(:confirmed?).and_return(true)
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
                                          }.stringify_keys,
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
                                          }.stringify_keys
                                        })
    end

    it 'returns the correct status' do
      expect(token_response.status).to eq(:ok)
    end
  end

  context 'revoke' do
    let(:token_response) { described_class.new(nil, token: token, action: :revoke) }

    it 'returns the correct body' do
      expect(token_response.body).to eq({})
    end

    it 'returns the correct status' do
      expect(token_response.status).to eq(:no_content)
    end
  end

  context 'sign up with an unconfirmed resource owner' do
    let(:token_response) { described_class.new(nil, token: token, action: :sign_up) }

    it 'returns the unconfirmed message' do
      allow(resource_owner).to receive(:confirmed?).and_return(false)

      expect(token_response.body[:confirmable]).to eq(
        confirmed: false,
        message: I18n.t('devise.api.error_response.registerable.signed_up_but_unconfirmed')
      )
    end
  end

  context 'sign up with a non confirmable resource owner' do
    let(:resource_owner) do
      FactoryBot.build(
        :admin_user,
        id: 1,
        email: 'test@development.com',
        created_at: Time.now,
        updated_at: Time.now
      )
    end
    let(:token_response) { described_class.new(nil, token: token, action: :sign_up) }

    it 'returns the default body without confirmable info' do
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
                                          }.stringify_keys
                                        })
    end
  end

  context 'when refresh tokens are disabled' do
    let(:token_response) { described_class.new(nil, token: token, action: :sign_in) }

    it 'does not return a refresh token' do
      allow(Devise.api.config.refresh_token).to receive(:enabled).and_return(false)

      expect(token_response.body).to eq({
                                          token: 'access_token',
                                          expires_in: 3600,
                                          token_type: 'Bearer',
                                          resource_owner: {
                                            id: 1,
                                            email: 'test@development.com',
                                            created_at: resource_owner.created_at,
                                            updated_at: resource_owner.updated_at
                                          }.stringify_keys
                                        })
    end
  end

  context 'when sign up extra fields are configured' do
    let(:resource_owner) do
      FactoryBot.build(
        :user,
        id: 1,
        email: 'test@development.com',
        name: 'John Doe',
        created_at: Time.now,
        updated_at: Time.now
      )
    end
    let(:token_response) { described_class.new(nil, token: token, action: :sign_in) }

    it 'returns the extra fields on the resource owner' do
      allow(Devise.api.config.sign_up).to receive(:extra_fields).and_return([:name])

      expect(token_response.body[:resource_owner]).to eq({
        id: 1,
        email: 'test@development.com',
        created_at: resource_owner.created_at,
        updated_at: resource_owner.updated_at,
        name: 'John Doe'
      }.stringify_keys)
    end
  end

  context 'info' do
    let(:token_response) { described_class.new(nil, token: token, action: :info) }

    it 'returns the correct body' do
      expect(token_response.body).to eq(
        {
          id: 1,
          email: 'test@development.com',
          created_at: resource_owner.created_at,
          updated_at: resource_owner.updated_at
        }.stringify_keys
      )
    end

    it 'returns the correct status' do
      expect(token_response.status).to eq(:ok)
    end
  end
end
