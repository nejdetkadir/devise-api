# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 20_230_113_213_619) do
  create_table 'devise_api_tokens', force: :cascade do |t|
    t.string 'resource_owner_type', null: false
    t.integer 'resource_owner_id', null: false
    t.string 'access_token', null: false
    t.string 'refresh_token'
    t.integer 'expires_in', null: false
    t.datetime 'revoked_at'
    t.string 'previous_refresh_token'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['access_token'], name: 'index_devise_api_tokens_on_access_token'
    t.index ['previous_refresh_token'], name: 'index_devise_api_tokens_on_previous_refresh_token'
    t.index ['refresh_token'], name: 'index_devise_api_tokens_on_refresh_token'
    t.index %w[resource_owner_type resource_owner_id], name: 'index_devise_api_tokens_on_resource_owner'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.integer 'sign_in_count', default: 0, null: false
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.string 'current_sign_in_ip'
    t.string 'last_sign_in_ip'
    t.string 'confirmation_token'
    t.datetime 'confirmed_at'
    t.datetime 'confirmation_sent_at'
    t.string 'unconfirmed_email'
    t.integer 'failed_attempts', default: 0, null: false
    t.string 'unlock_token'
    t.datetime 'locked_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['confirmation_token'], name: 'index_users_on_confirmation_token', unique: true
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
    t.index ['unlock_token'], name: 'index_users_on_unlock_token', unique: true
  end
end
