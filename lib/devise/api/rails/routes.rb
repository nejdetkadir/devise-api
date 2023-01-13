# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      protected

      def devise_api(mapping, controllers)
        controller = controllers.fetch(:tokens, 'devise/api/tokens')
        path = mapping.path_names.fetch(:tokens, 'tokens')

        resource :tokens, only: [], controller: controller, path: path do
          collection do
            post :revoke, as: :revoke
            post :refresh, as: :refresh
            post :sign_up, as: :sign_up
            post :sign_in, as: :sign_in
            get :info, as: :info
          end
        end
      end
    end
  end
end
