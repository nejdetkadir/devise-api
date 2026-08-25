# frozen_string_literal: true

class AdminUser < ApplicationRecord
  # A bare devise model without the optional trackable, lockable and confirmable modules
  devise :database_authenticatable, :registerable, :validatable, :api
end
