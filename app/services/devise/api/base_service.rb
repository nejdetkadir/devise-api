# frozen_string_literal: true

require 'dry/monads/all'
require 'dry-initializer'
require 'dry-types'

module Types
  include Dry.Types()
end

module Devise
  module Api
    class BaseService
      extend Dry::Initializer

      include Dry::Monads
      include Dry::Monads::Do
    end
  end
end
