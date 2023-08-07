# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  before_action :authenticate_devise_api_token!

  def index
    render json: { success: true }
  end
end
