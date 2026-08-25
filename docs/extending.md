# Extending & Customization Points

Supported ways for a host app to change behavior, ordered from lightest to heaviest. Everything here is exercised by the test suite or README examples — treat as public API.

## 1. Configuration

Most behavior is a config knob — TTLs, generators, header/param names, callbacks, sign-up fields. See [configuration.md](configuration.md). The `before_*` / `after_successful_*` procs cover most "hook into the flow" needs without subclassing.

## 2. Custom routes / controller per scope

```ruby
devise_for :customers,
           controllers: { tokens: 'customers/api/tokens' },  # controller override
           path: 'accounts'                                   # path scope override
```

The `:tokens` key is read by `Mapper#devise_api` (`lib/devise/api/rails/routes.rb`). The path segment itself comes from `mapping.path_names.fetch(:tokens, 'tokens')`, so `devise_for :users, path_names: { tokens: 'sessions' }` renames the `/tokens` segment. Covered by `spec/routing/customized_routes_spec.rb`.

The custom controller should subclass `Devise::Api::TokensController` (the dummy app's `spec/dummy/app/controllers/devise/api/customized_tokens_controller.rb` is the reference example).

## 3. Response decorators

Response classes are plain Ruby — `prepend` a module to reshape payloads:

```ruby
module Devise::Api::Responses::TokenResponseDecorator
  def body
    default_body.merge(roles: resource_owner.roles)
  end
end

Devise::Api::Responses::TokenResponse.prepend Devise::Api::Responses::TokenResponseDecorator
```

Same pattern works for `ErrorResponse`. Useful methods to override: `body`, `default_body`, `default_resource_owner`, `status`.

## 4. Custom token model

Subclass and point config at it (as a **string**):

```ruby
class ApiToken < Devise::Api::Token
  # scopes, extra columns, etc.
end

Devise.setup do |config|
  config.api.configure { |api| api.base_token_model = 'ApiToken' }
end
```

Every lookup, association, and generator in the gem resolves through `Devise.api.config.base_token_model.constantize`, so the subclass is used everywhere consistently.

## 5. Custom base controller

`api.base_controller = 'Api::BaseController'` changes what `TokensController` inherits from. Caveat: the superclass is resolved when `TokensController` is first loaded, so set it in the Devise initializer (before any request). The base must provide Devise's controller API (`resource_class` etc.) — subclassing `DeviseController` or including its behavior is the safe route.

## 6. Custom services in the host app

`Devise::Api::BaseService` is designed to be inherited by host-app services (dry-initializer options + dry-monads). See README "Using devise base services". This is additive — the gem never calls host services.

## Protected-endpoint integration (the common case)

```ruby
class Api::V1::BaseController < ActionController::Base
  skip_before_action :verify_authenticity_token, raise: false
  before_action :authenticate_devise_api_token!
end
```

Helpers available in **every** controller (mixed in on load): `authenticate_devise_api_token!`, `current_devise_api_token`, `current_devise_api_user`, `current_devise_api_refresh_token`.

## What is NOT a supported extension point

- Reaching into `Devise::Api::Token` by constant from library code (breaks `base_token_model` substitution).
- Per-model/per-scope configuration — config is global; two Devise scopes share TTLs, callbacks, and token model. If you need per-scope behavior, branch inside the callback procs (they receive `resource_class`/`resource_owner`).
