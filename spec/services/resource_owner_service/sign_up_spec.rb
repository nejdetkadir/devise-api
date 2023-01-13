# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::ResourceOwnerService::SignUp do
  it 'inherits from Devise::Api::BaseService' do
    expect(described_class).to be < Devise::Api::BaseService
  end
end
