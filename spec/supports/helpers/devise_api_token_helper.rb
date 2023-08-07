# frozen_string_literal: true

module DeviseApiTokenHelper
  def authentication_headers_for(resource_owner, token = nil, token_type = :access_token)
    token = FactoryBot.create(:devise_api_token, resource_owner: resource_owner) if token.blank?
    token_value = token.send(token_type)

    { 'Authorization': "Bearer #{token_value}" }
  end
end

RSpec.configuration.include DeviseApiTokenHelper, type: :request
