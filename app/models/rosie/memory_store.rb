module Rosie
  class MemoryStore
    @@store = {}
    @@monitor = Mutex.new
    def self.fetch_invalidate object_key, invalidation_key
      value = nil
      @@monitor.synchronize do
        if !@@store.has_key?(object_key) || !@@store[object_key].has_key?(invalidation_key)
          @@store[object_key] = {}
        end
        value = (@@store[object_key][invalidation_key] ||= yield)
      end
      return value
    end
    def self.[]= object_key, value
      @@monitor.synchronize do
        @@store[object_key] = value
      end
    end
    def self.[] object_key
      @@store[object_key]
    end
  end
end
