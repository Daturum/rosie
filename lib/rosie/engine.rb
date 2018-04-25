require 'paper_trail'
require 'request_store'
require 'jquery-rails'

module Rosie
  class Engine < ::Rails::Engine
    isolate_namespace Rosie
  end
end
