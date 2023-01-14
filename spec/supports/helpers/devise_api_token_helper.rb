# frozen_string_literal: true

module DeviseApiTokenHelper
  def authentication_headers_for(resource_owner, token = nil)
    token = FactoryBot.create(:devise_api_token, resource_owner: resource_owner) if token.blank?

    { 'Authorization': "Bearer #{token.access_token}" }
  end
end

RSpec.configuration.include DeviseApiTokenHelper, type: :request
