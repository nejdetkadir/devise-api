# frozen_string_literal: true

class AddUniqueTokenIndexesToDeviseApiTokens < ActiveRecord::Migration[7.0]
  def change
    remove_index :devise_api_tokens, :access_token
    remove_index :devise_api_tokens, :refresh_token
    add_index :devise_api_tokens, :access_token, unique: true
    add_index :devise_api_tokens, :refresh_token, unique: true
  end
end
