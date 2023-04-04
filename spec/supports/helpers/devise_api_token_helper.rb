# frozen_string_literal: true

module DeviseApiTokenHelper
  def authentication_headers_for(resource_owner, token = nil, refreshing = nil)
    token = FactoryBot.create(:devise_api_token, resource_owner: resource_owner) if token.blank?
    bearer = refreshing ? token.refresh_token : token.access_token

    { 'Authorization': "Bearer #{bearer}" }
  end
end

RSpec.configuration.include DeviseApiTokenHelper, type: :request
