require "rosie/engine"

module Rosie
  # Your code goes here...
  def self.interfaces_path
    p = Rails.root.join('app', 'interfaces')
    FileUtils.mkdir_p(p)
    p
  end
end
