[![Gem Version](https://badge.fury.io/rb/devise-api.svg)](https://badge.fury.io/rb/devise-api)
![test](https://github.com/nejdetkadir/devise-api/actions/workflows/test.yml/badge.svg?branch=main)
![rubocop](https://github.com/nejdetkadir/devise-api/actions/workflows/rubocop.yml/badge.svg?branch=main)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
![Ruby Version](https://img.shields.io/badge/ruby_version->=_2.7.0-blue.svg)

# Devise API

The `devise-api` gem is a convenient way to add authentication to your Ruby on Rails API application using the [devise](https://github.com/heartcombo/devise) gem. It provides support for access tokens and refresh tokens, which allow you to authenticate API requests and keep the user's session active for a longer period of time.

Here's how it works:

- When a user logs in to your API application, the `devise-api` gem generates an access token and a refresh token.
- The access token is included in the API request headers and is used to authenticate the user on each subsequent request.
- The refresh token is stored on the client side (e.g. in a browser cookie or on a mobile device) and is used to obtain a new access token when the original access token expires.
- This allows the user to remain logged in and make API requests without having to constantly re-enter their login credentials.

Overall, the `devise-api` gem is a useful tool for adding secure authentication to your Ruby on Rails API application.

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

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nejdetkadir/devise-api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/nejdetkadir/devise-api/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).

## Code of Conduct

Everyone interacting in the Devise::Api project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/nejdetkadir/devise-api/blob/main/CODE_OF_CONDUCT.md).
