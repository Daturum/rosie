module Rosie
  class AssetFile < ApplicationRecord
    has_paper_trail ignore: [:file_contents]
    validates :filename, uniqueness: { message: "file exists: %{value}"}, presence: true
    validates :size, :numericality => { less_than: 10.megabytes }

    # CLASS METHODS

    def self.cache_invalidation_key
      RequestStore['AssetFile.cache_invalidation_key'] ||= Programmer.last_action_timestamp.to_i
        #average('extract(epoch from updated_at)').to_s
    end

    def self.get_file_by_hashed_path hashed_path
      hash, filename = hashed_path.split("__", 2)
      @file = find_by(filename: filename)
      @file.cache_hash == hash ? @file : nil
    end

    def self.hashed_path filename
      MemoryStore.fetch_invalidate "AssetFile.http_hashed_path #{filename}", cache_invalidation_key do
        file = find_by(filename: filename)
        !file ? nil : "/asset_files/#{file.cache_hash}__#{URI.escape filename}"
      end
    end

    def self.[] filename; find_by(filename: filename) end

    # INSTANCE METHODS


    def initialize(params = {})
      file = params.delete(:file)
      super
      if file
        self.filename = File.basename(file.original_filename)
        self.content_type = file.content_type
        self.size = file.size
        self.file_contents = file.read
      end
    end

    def cache_hash
      "#{updated_at.to_i}#{filename}#{Rails.application.secrets.secret_key_base}".hash.to_s[-5..-1]
    end
  end
end
