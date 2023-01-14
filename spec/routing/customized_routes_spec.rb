# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Customized routes' do
  # create and customize routes for devise_for :users
  before :all do
    Rails.application.routes.disable_clear_and_finalize = true

    Rails.application.routes.clear!

    Rails.application.routes.draw do
      devise_for :users, controllers: { tokens: 'devise/api/customized_tokens' }, path: 'accounts'
    end
  end

  after :all do
    Rails.application.routes.clear!

    load File.expand_path('../dummy/config/routes.rb', __dir__)
  end

  it 'routes to /accounts/tokens/refresh' do
    expect(post: '/accounts/tokens/refresh').to route_to('devise/api/customized_tokens#refresh')
  end

  it 'routes to /accounts/tokens/revoke' do
    expect(post: '/accounts/tokens/revoke').to route_to('devise/api/customized_tokens#revoke')
  end

  it 'routes to /accounts/tokens/info' do
    expect(get: '/accounts/tokens/info').to route_to('devise/api/customized_tokens#info')
  end

  it 'routes to /accounts/tokens/sign_in' do
    expect(post: '/accounts/tokens/sign_in').to route_to('devise/api/customized_tokens#sign_in')
  end

  it 'routes to /accounts/tokens/sign_up' do
    expect(post: '/accounts/tokens/sign_up').to route_to('devise/api/customized_tokens#sign_up')
  end
end
