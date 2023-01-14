# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api do
  it 'has a version number' do
    expect(Devise::Api::VERSION).not_to be nil
  end

  it 'has a configuration for api extension' do
    expect(Devise.api.class).to eq Devise::Api::Configuration
  end

  it 'has a default configuration for api extension' do
    config = Devise::Api::Configuration.new

    allow(Devise).to receive(:api).and_return(config)
    expect(Devise.api).to eq config
  end

  it 'added to devise modules' do
    expect(Devise::ALL).to include :api
  end
end
