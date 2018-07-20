module Rosie
  class Version < PaperTrail::Version
    self.table_name = 'rosie.versions'
  end
end
