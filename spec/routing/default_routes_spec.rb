# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Default routes' do
  it 'routes to /users/tokens/revoke' do
    expect(post: '/users/tokens/revoke').to route_to('devise/api/tokens#revoke')
  end

  it 'routes to /users/tokens/refresh' do
    expect(post: '/users/tokens/refresh').to route_to('devise/api/tokens#refresh')
  end

  it 'routes to /users/tokens/info' do
    expect(get: '/users/tokens/info').to route_to('devise/api/tokens#info')
  end

  it 'routes to /users/tokens/sign_in' do
    expect(post: '/users/tokens/sign_in').to route_to('devise/api/tokens#sign_in')
  end

  it 'routes to /users/tokens/sign_up' do
    expect(post: '/users/tokens/sign_up').to route_to('devise/api/tokens#sign_up')
  end
end
