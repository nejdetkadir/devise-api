# frozen_string_literal: true

FactoryBot.define do
  factory :devise_api_token, class: 'Devise::Api::Token' do
    association :resource_owner, factory: :user
    access_token { SecureRandom.hex(32) }
    refresh_token { SecureRandom.hex(32) }
    expires_in { 1.hour.to_i }

    trait :access_token_expired do
      created_at { 2.hours.ago }
    end

    trait :refresh_token_expired do
      created_at { 2.months.ago }
    end

    trait :revoked do
      revoked_at { 5.minutes.ago }
    end
  end
end
