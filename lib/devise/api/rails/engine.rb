# frozen_string_literal: true

module Devise
  module Api
    module Rails
      class Engine < ::Rails::Engine
        isolate_namespace Devise::Api
      end
    end
  end
end
