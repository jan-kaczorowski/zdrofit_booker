class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def authenticate_user!
    return unless session[:user_id].blank?

    redirect_to root_path and return
  end

  def fetch_user
    return if session[:user_id].blank?

    @user = ZdrofitUser.find(session[:user_id])
  end
end
