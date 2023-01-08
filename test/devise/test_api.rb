# frozen_string_literal: true

require 'test_helper'

module Devise
  class TestApi < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Devise::Api::VERSION
    end
  end
end
