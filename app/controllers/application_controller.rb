class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  def basic
    raise 'Basic auth info not found.' if Rails.application.secrets.basic_auth_user.nil? || Rails.application.secrets.basic_auth_password.nil?
    authenticate_or_request_with_http_basic do |user, pass|
      user == Rails.application.secrets.basic_auth_user && pass == Rails.application.secrets.basic_auth_password
    end
  end
end
