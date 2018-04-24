module Rosie
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    def home
      render plain: 'Hello World!'
    end
  end
end
