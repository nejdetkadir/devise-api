# frozen_string_literal: true

module Devise
  module Api
    module Rails
      class Engine < ::Rails::Engine
        isolate_namespace Devise::Api

        # Keep raw token secrets out of the host app's request logs (tokens can arrive as
        # query/body params when authorization.location is :params or :both)
        initializer 'devise.api.filter_parameters' do |app|
          app.config.filter_parameters |= %i[access_token refresh_token previous_refresh_token]
        end
      end
    end
  end
end
