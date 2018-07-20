require 'paper_trail'
require 'request_store'
require 'jquery-rails'

module Rosie
  class Engine < ::Rails::Engine
    isolate_namespace Rosiz

    Rosie.singleton_class.instance_eval do
      define_method(:table_name_prefix) { "rosie.rosie_" }
    end
  end
end
