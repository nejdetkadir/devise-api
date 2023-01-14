# frozen_string_literal: true

require_relative 'lib/devise/api/version'

# rubocop:disable Layout/LineLength
Gem::Specification.new do |spec|
  spec.name = 'devise-api'
  spec.version = Devise::Api::VERSION
  spec.authors = ['nejdetkadir']
  spec.email = ['nejdetkadir.550@gmail.com']

  spec.summary = "The devise-api gem is a convenient way to add authentication to your Ruby on Rails application using the devise gem.
                 It provides support for access tokens and refresh tokens, which allow you to authenticate API requests and
                 keep the user's session active for a longer period of time on the client side. It can be installed by adding the gem to your Gemfile,
                 running migrations, and adding the :api module to your devise model. The gem is fully configurable,
                 allowing you to set things like token expiration times and token generators."

  spec.description = spec.summary
  spec.homepage = "https://github.com/nejdetkadir/#{spec.name}"
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'devise', '>= 4.7.2'
  spec.add_dependency 'dry-configurable', '~> 1.0', '>= 1.0.1'
  spec.add_dependency 'dry-initializer', '>= 3.1.1'
  spec.add_dependency 'dry-monads', '>= 1.6.0'
  spec.add_dependency 'dry-types', '>= 1.7.0'
  spec.add_dependency 'rails', '>= 6.0.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
# rubocop:enable Layout/LineLength
