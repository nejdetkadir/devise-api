# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Api::Rails::Engine do
  it 'adds the token secrets to the host application filter parameters' do
    expect(::Rails.application.config.filter_parameters)
      .to include(:access_token, :refresh_token, :previous_refresh_token)
  end
end
