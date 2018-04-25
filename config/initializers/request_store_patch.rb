RequestStore.class_eval do
  def self.[] key; self.store[key] end
  def self.[]= key, value; self.store[key] = value end
end
