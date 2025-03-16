class HomeController < ApplicationController
  before_action :authenticate_user!, except: %i[index login]
  before_action :fetch_user, except: %i[index login]
end
