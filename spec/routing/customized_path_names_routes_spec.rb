# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Customized path names routes' do
  # create and customize routes for devise_for :users
  before :all do
    Rails.application.routes.disable_clear_and_finalize = true

    Rails.application.routes.clear!

    Rails.application.routes.draw do
      devise_for :users, path_names: { tokens: 'sessions' }
    end
  end

  after :all do
    Rails.application.routes.clear!

    load File.expand_path('../dummy/config/routes.rb', __dir__)
  end

  it 'routes to /users/sessions/refresh' do
    expect(post: '/users/sessions/refresh').to route_to('devise/api/tokens#refresh')
  end

  it 'routes to /users/sessions/revoke' do
    expect(post: '/users/sessions/revoke').to route_to('devise/api/tokens#revoke')
  end

  it 'routes to /users/sessions/info' do
    expect(get: '/users/sessions/info').to route_to('devise/api/tokens#info')
  end

  it 'routes to /users/sessions/sign_in' do
    expect(post: '/users/sessions/sign_in').to route_to('devise/api/tokens#sign_in')
  end

  it 'routes to /users/sessions/sign_up' do
    expect(post: '/users/sessions/sign_up').to route_to('devise/api/tokens#sign_up')
  end
end
