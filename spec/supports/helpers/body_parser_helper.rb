# frozen_string_literal: true

module BodyParserHelper
  def parsed_body
    JSON.parse(response.body, object_class: OpenStruct)
  end
end

RSpec.configuration.include BodyParserHelper, type: :request
