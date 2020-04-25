module Rosie
  class Component < Rosie::ApplicationRecord
    has_paper_trail(
      ignore: [:updated_at, :editing_locked_by, :loading_error],
      meta: {commit_message: :version_commit_message})
    attr_accessor :version_commit_message
    validates :version_commit_message,  presence: true

    validates :path,            uniqueness: true, presence: true
    # validates :partial,         inclusion: { in: [ true, false ] }
    validates :component_type,  inclusion: { in: lambda do |c|
      permitted_types = c.class.permitted_component_types
      if c.persisted? && !c.component_type_changed?; permitted_types << c.component_type end
      permitted_types
     end }
    validates :context,         inclusion: { in: lambda do |c| c.permitted_contexts end }
    validates :format,          inclusion: { in: lambda do |c| c.permitted_formats end }
    validates :handler,         inclusion: { in: lambda do |c| c.permitted_handlers end }
    validates :name,            format: /\A[a-z0-9_]+\z/i
    validates :name,            { inclusion: { in: lambda do |c| [c.component_type] end },
                                    if: lambda do |c| c.class.component_types[c.component_type][:occurence] == 'single' end }
    validates :name,            { exclusion: { in: lambda do |c| c.class.component_types.keys.map(&:to_s) end },
                                    if: lambda do |c| c.class.component_types[c.component_type][:occurence] == 'multiple' end }
    serialize :loading_error,   ActiveSupport::HashWithIndifferentAccess


    # CLASS METHODS

    def self.component_types
      ComponentTypes.types
    end

    def self.[] path
      find_by path: path
    end

    # Tracking components used in request

    def self.track_request_components!; RequestStore["request_components"] = {}; end
    def self.request_components_tracked?; !!RequestStore["request_components"]; end
    def self.add_request_component_path component_path
      return unless request_components_tracked?
      RequestStore["request_components"][component_path] ||= 0
      RequestStore["request_components"][component_path] += 1
    end
    def self.request_components_usage; RequestStore["request_components"]; end

    # Permitted component types logic

    def self.permitted_component_types
      Rails.cache.fetch("permitted_component_types #{
        Rosie::Version.where(item_type: 'Rosie::Component').maximum(:id)}") do

        component_types.keys.reject{ |component_type|
          new(component_type: component_type).permitted_contexts.blank?
        }
      end
    end

    # INSTANCE MEHTODS

    # MULTIPLE PROGRAMMER EDITING LOCKING

    def get_locking_programmer
      return false if !persisted?
      if updated_at > Programmer::EDIT_TIMEOUT.ago && editing_locked_by != Programmer.current
        return editing_locked_by
      else
        return nil
      end
    end

    def update_lock! remove_other_locks: true
      raise "Cannot lock editing: already locked by #{editing_locked_by} @ #{updated_at}" if get_locking_programmer
      ActiveRecord::Base.transaction do
        if remove_other_locks
          self.class.where(editing_locked_by: Programmer.current).update_all(
            editing_locked_by: nil, updated_at: 0.seconds.ago)
        end

        assign_attributes(editing_locked_by: Programmer.current, updated_at: 0.seconds.ago)
        save!(:validate => false)
      end
    end

    def latest_version_timestamp
      (versions.limit(1).order('id DESC').pluck(:created_at)[0] || created_at).to_i
    end

    def unlock_editing!
      raise "Cannot unlock editing: already locked by #{editing_locked_by} @ #{updated_at}" if get_locking_programmer
      self.class.where(editing_locked_by: Programmer.current).update_all(editing_locked_by: nil, updated_at: 0.seconds.ago)
    end

    def delete_recent_versions_of_current_programmer_except_latest
      return unless versions.last
      versions.where("created_at > ?", Programmer::EDIT_TIMEOUT.ago).where("id != ?", versions.last.id)
        .where(whodunnit: Programmer.current).destroy_all
    end

    def persisted?; !new_record? && !destroyed? end

    # STORAGE

    def name
      path.present? ? path.rpartition('/')[-1] : ""
    end
    def context
      result = (path.rpartition('/')[0] if path)
      result.present? ? result : 'root';
    end
    def parent
      context.split('/')[-1]
    end
    def root_context
      path.split('/', 2)[0] if path
    end
    def occurence
      self.class.component_types[component_type][:occurence]
    end

    # permission and validation logic

    def permitted_contexts
      context_types = [self.class.component_types[component_type][:context_types]].flatten
      available_contexts = self.class.where(component_type: context_types)
      if self.class.component_types[component_type][:occurence] == 'single'
        available_contexts = available_contexts.where( # TODO remove pg_dependency
          "NOT EXISTS (SELECT 1 FROM rosie.rosie_components c WHERE c.component_type = ?
          AND c.path ILIKE CONCAT(rosie.rosie_components.path, '/%'))",
          component_type)
      end
      result = available_contexts.pluck(:path)
      if self.persisted?;                result << context end # if context already taken by self
      if context_types.include?('root'); result << 'root'  end # if allowed_contexts_types have root
      return result.uniq
    end
    def permitted_formats
      [self.class.component_types[component_type][:formats]].flatten
    end
    def permitted_handlers
      [self.class.component_types[component_type][:handlers]].flatten
    end
    def set_context_and_name context, name
      name = (occurence == 'multiple' ? name : component_type)
      self.path = "#{context}/#{name}".sub(/^root\//, '')
    end

    # generating cache_hash to invalidate on change

    def cache_hash
      "#{body}#{path}#{Rails.application.secrets.secret_key_base}#{
        AssetFile.cache_invalidation_key}".hash.to_s[-8..-1]
    end

    def subcomponents
      self.class.where('path like ?', "#{path}/%")
    end

  end
end
