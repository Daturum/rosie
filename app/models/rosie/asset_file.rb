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
      segments = hashed_path.split('/')
      hash, last_segment = segments[-1].split("__", 2)
      segments[-1] = last_segment
      filename = segments.join('/')
      @file = find_by(filename: filename)
      @file.cache_hash == hash ? @file : nil
    end

    def self.hashed_path filename
      MemoryStore.fetch_invalidate "AssetFile.http_hashed_path #{filename}", cache_invalidation_key do
        file = find_by(filename: filename)
        if file
          segments = filename.split('/').map{|s| URI.escape s}
          segments[-1] = "#{file.cache_hash}__#{segments[-1]}"
          "/files/#{segments.join('/')}"
        else
          nil
        end
      end
    end

    def self.[] filename; find_by(filename: filename) end

    def self.css_or_js? filename; !!filename.match(/\.(css|js)$/) end

    # INSTANCE METHODS

    def initialize(params = {})
      file = params.delete(:file)
      super
      if file
        self.filename = file.original_filename
        self.content_type = file.content_type
        self.size = file.size
        self.file_contents = file.read
      end
    end
    def cache_hash
      Digest::MD5.hexdigest("#{updated_at.to_i}#{filename}#{
        Rails.application.secrets.secret_key_base}")[-5..-1]
    end
    def cache_hash
      autoreplace_key = autoreplace_filepaths ? Programmer.last_action_timestamp : ''
      key = "#{autoreplace_key}#{updated_at.to_i}#{filename}#{Rails.application.secrets.secret_key_base}"
      hash = Digest::MD5.hexdigest(key)[-5..-1]
    end
  end
end
