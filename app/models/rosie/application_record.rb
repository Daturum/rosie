module Rosie
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    self.table_name_prefix = 'rosie.'

    def self.has_paper_trail(options = {})
      options ||= {}
      options[:class_name] ||= 'Rosie::Version'
      super(options)
    end
  end
end
