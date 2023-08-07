[![Gem Version](https://badge.fury.io/rb/devise-api.svg)](https://badge.fury.io/rb/devise-api)
![test](https://github.com/nejdetkadir/devise-api/actions/workflows/test.yml/badge.svg?branch=main)
![rubocop](https://github.com/nejdetkadir/devise-api/actions/workflows/rubocop.yml/badge.svg?branch=main)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
![Ruby Version](https://img.shields.io/badge/ruby_version->=_2.7.0-blue.svg)

# Devise API
The devise-api gem is a convenient way to add authentication to your Ruby on Rails application using the devise gem. It provides support for access tokens and refresh tokens, which allow you to authenticate API requests and keep the user's session active for a longer period of time on the client side. It can be installed by adding the gem to your Gemfile, running migrations, and adding the :api module to your devise model. The gem is fully configurable, allowing you to set things like token expiration times and token generators.

Here's how it works:

- When a user logs in to your Rails application, the `devise-api` gem generates an access token and a refresh token.
- The access token is included in the API request headers and is used to authenticate the user on each subsequent request.
- The refresh token is stored on the client side (e.g. in a browser cookie or on a mobile device) and is used to obtain a new access token when the original access token expires.
- This allows the user to remain logged in and make API requests without having to constantly re-enter their login credentials.

Overall, the `devise-api` gem is a useful tool for adding secure authentication to your Ruby on Rails application.

## Installation

Install the gem and add to the application's Gemfile by executing:
```bash
$ bundle add devise-api
```

Or add the following line to the application's Gemfile:
```ruby
gem 'devise-api', github: 'nejdetkadir/devise-api', branch: 'main'
```

If bundler is not being used to manage dependencies, install the gem by executing:
```bash
gem install devise-api
```

After that, you need to generate relevant migrations and locales by executing:
```bash
$ rails generate devise_api:install
```

This will introduce two changes:
- Locale files in `config/locales/devise_api.en.yml`
- Migration file in `db/migrate` to create devise api tokens table

Now you're ready to run the migrations:
```bash
$ rails db:migrate
```

Finally, you need to add `:api` module to your devise model. For example:
```ruby
class User < ApplicationRecord
  devise :database_authenticatable, 
         :registerable, 
         :recoverable,
         :rememberable,
         :validatable,
         :api # <--- Add this module
end
```

Your user model is now ready to use `devise-api` gem. It will draw routes for token authenticatable and token refreshable.

| Prefix | Verb | URI Pattern | Controller#Action        |
|--------|------|------------|--------------------------|
| revoke_user_tokens | POST | /users/tokens/revoke | devise/api/tokens#revoke |
| refresh_user_tokens | POST | /users/tokens/refresh | devise/api/tokens#refresh |
| sign_up_user_tokens | POST | /users/tokens/sign_up | devise/api/tokens#sign_up |
| sign_in_user_tokens | POST | /users/tokens/sign_in | devise/api/tokens#sign_in |
| info_user_tokens | GET | /users/tokens/info | devise/api/tokens#info |

### You can look up the [example requests](#example-api-requests).

## Configuration

`devise-api` is a full configurable gem. You can configure it to your needs. Here is a basic usage example:

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.api.configure do |api|
    # Access Token
    api.access_token.expires_in = 1.hour
    api.access_token.expires_in_infinite = ->(_resource_owner) { false }
    api.access_token.generator = ->(_resource_owner) { Devise.friendly_token(60) }


    # Refresh Token
    api.refresh_token.enabled = true
    api.refresh_token.expires_in = 1.week
    api.refresh_token.generator = ->(_resource_owner) { Devise.friendly_token(60) }
    api.refresh_token.expires_in_infinite = ->(_resource_owner) { false }

    # Sign up
    api.sign_up.enabled = true

    # Authorization
    api.authorization.key = 'Authorization'
    api.authorization.scheme = 'Bearer'
    api.authorization.location = :both # :header or :params or :both
    api.authorization.params_key = 'access_token'


    # Base classes
    api.base_token_model = 'Devise::Api::Token'
    api.base_controller = '::DeviseController'


    # After successful callbacks
    api.after_successful_sign_in = ->(_resource_owner, _token, _request) { }
    api.after_successful_sign_up = ->(_resource_owner, _token, _request) { }
    api.after_successful_refresh = ->(_resource_owner, _token, _request) { }
    api.after_successful_revoke = ->(_resource_owner, _token, _request) { }


    # Before callbacks
    api.before_sign_in = ->(_params, _request, _resource_class) { }
    api.before_sign_up = ->(_params, _request, _resource_class) { }
    api.before_refresh = ->(_params, _request, _resource_class) { }
    api.before_revoke = ->(_params, _request, _resource_class) { }
  end
end
```

## Routes

You can configure the tokens routes with the orginally `devise_for` method. For example:
```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :customers, 
             controllers: { tokens: 'customers/api/tokens' }
end
```

## Usage
`devise-api` module works with `:lockable` and `:confirmable` modules. It also works with `:trackable` module.

`devise-api` provides a set of controllers and helpers to help you implement authentication in your Rails application. Here's a quick overview of the available controllers and helpers:

- [Devise::Api::TokensController](https://github.com/nejdetkadir/devise-api/tree/main/app/controllers/devise/api/tokens_controller.rb) - This controller is responsible for generating access tokens and refresh tokens. It also provides actions for refreshing access tokens and revoking refresh tokens.

- [Devise::Api::Token](https://github.com/nejdetkadir/devise-api/tree/main/lib/devise/api/token.rb) - This model is responsible for storing access tokens and refresh tokens in the database.

- [Devise::Api::Responses::ErrorResponse](https://github.com/nejdetkadir/devise-api/tree/main/lib/devise/api/responses/error_response.rb) - This class is responsible for generating error responses. It also provides a set of error types and helpers to help you implement error responses in your Rails application.

- [Devise::Api::Responses::TokenResponse](https://github.com/nejdetkadir/devise-api/tree/main/lib/devise/api/responses/token_response.rb) - This class is responsible for generating token responses. It also provides actions for generating access tokens and refresh tokens for each action.

## Overriding Responses
You can prepend your decorators to the response classes to override the default responses. For example:
```ruby
# app/lib/devise/api/responses/token_response_decorator.rb
module Devise::Api::Responses::TokenResponseDecorator
  def body
    return default_body.merge({ roles: resource_owner.roles })
  end
end
```

Then you need to prepend your decorator to the response class. For example:

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
end

Devise::Api::Responses::TokenResponse.prepend Devise::Api::Responses::TokenResponseDecorator
```

## Using helpers
`devise-api` provides a set of helpers to help you implement authentication in your Rails application. Here's a quick overview of the available helpers:

Example:
```ruby
# app/controllers/api/v1/orders_controller.rb
class Api::V1::OrdersController < YourBaseController
  skip_before_action :verify_authenticity_token, raise: false  
  before_action :authenticate_devise_api_token!

  def index
    render json: current_devise_api_user.orders, status: :ok
  end

  def show
    devise_api_token = current_devise_api_token
    render json: devise_api_token.resource_owner.orders.find(params[:id]), status: :ok
  end
end
```

## Using devise base services
`devise-api` provides a set of base services to help you implement authentication in your Rails application. Here's a quick overview of the available services:

- [Devise::Api::BaseService](https://github.com/nejdetkadir/devise-api/tree/main/app/services/devise/api/base_service.rb) - This service is useful for creating and updating resources. It is inherited by the following gems.
- [dry-monads](https://dry-rb.org/gems/dry-monads)
- [dry-types](https://dry-rb.org/gems/dry-types)
- [dry-initializer](https://dry-rb.org/gems/dry-initializer)

You can create a service by inheriting the `Devise::Api::BaseService` class. For example:
```ruby
# app/services/devise/api/tokens_service/v2/create.rb
module Devise::Api::TokensService::V2
  class Create < Devise::Api::BaseService
    option :params, type: Types::Hash, reader: true
    option :resource_class, type: Types::Class, reader: true

    def call
      ...

      Success(resource)
    end
  end
end
```

Then you can call the service in your controller. For example:
```ruby
# app/controllers/api/v1/tokens_controller.rb
class Api::V1::TokensController < YourBaseController
  skip_before_action :verify_authenticity_token, raise: false

  def create
    service = Devise::Api::TokensService::V2::Create.call(params: params, resource_class: Customer || resource_class)
    if service.success?
      render json: service.success, status: :created
    else
      render json: service.failure, status: :unprocessable_entity
    end
  end
end
```

## Example API requests

### Sign in
```curl
curl --location --request POST 'http://127.0.0.1:3000/users/tokens/sign_in' \
--header 'Content-Type: application/json' \
--data-raw '{
    "email": "test@development.com",
    "password": "123456"
}'
```

### Sign up
```curl
curl --location --request POST 'http://127.0.0.1:3000/users/tokens/sign_up' \
--header 'Content-Type: application/json' \
--data-raw '{
    "email": "test@development.com",
    "password": "123456"
}'
```

### Refresh token
```curl
curl --location --request POST 'http://127.0.0.1:3000/users/tokens/refresh' \
--header 'Authorization: Bearer <refresh_token>'
```

### Revoke
```curl
curl --location --request POST 'http://127.0.0.1:3000/users/tokens/revoke' \
--header 'Authorization: Bearer <access_token>'
```

### Info
```curl
curl --location --request GET 'http://127.0.0.1:3000/users/tokens/info' \
--header 'Authorization: Bearer <access_token>'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nejdetkadir/devise-api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/nejdetkadir/devise-api/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).

## Code of Conduct

Everyone interacting in the Devise::Api project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/nejdetkadir/devise-api/blob/main/CODE_OF_CONDUCT.md).
