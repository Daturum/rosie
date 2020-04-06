module Rosie
  class ComponentLoaderMiddleware
    @@currently_loaded_components_directory_mtime = nil
    def self.code_loading_timeout_in_seconds; 0.5 end

    def initialize app
      @app = app
    end
    def self.current
      RequestStore["ComponentLoaderMiddleware.current"]
    end
    def self.current= value
      RequestStore["ComponentLoaderMiddleware.current"] = value
    end

    def components_directory
      RequestStore["components_directory"] ||= 'Rosie::ComponentTypes'.constantize.components_directory
    end

    def component_write_files_required?
      return false unless 'Rosie::Component'.safe_constantize.try :table_exists?
      Rails.logger.info "Checking WRITE_required:\ncomponents_directory #{components_directory}\nDir.exists?(components_directory) #{Dir.exists?(components_directory)}\nFile.mtime(components_directory).to_i: #{File.mtime(components_directory).to_i rescue nil}\n'Rosie::Programmer'.constantize.last_action_timestamp.to_i: #{'Rosie::Programmer'.constantize.last_action_timestamp.to_i}\nThread.current.object_id: #{Thread.current.object_id}"
      components_directory &&                                                  # if components and programmers exist in database
        (!Dir.exists?(components_directory) ||                                   # if these components aren't written to files
        (File.mtime(components_directory).to_i != 'Rosie::Programmer'.constantize.last_action_timestamp.to_i))    # or current loaded version is obsolete
    end

    def initialization_required?
      Rails.logger.info "Checking INITIALIZATION_required:\n@@currently_loaded_components_directory_mtime: #{@@currently_loaded_components_directory_mtime}\nFile.mtime(components_directory).to_i: #{File.mtime(components_directory).to_i  rescue nil}\nThread.current.object_id: #{Thread.current.object_id}"
      component_write_files_required? ||
        (Dir.exists?(components_directory) && (@@currently_loaded_components_directory_mtime != File.mtime(components_directory).to_i))
    end

    def call env
      dup.threadsafe_call env
    end

    def threadsafe_call env
      self.class.current = self
      check_and_initialize_rails_components_if_needed
      @@currently_loaded_components_directory_mtime = (File.mtime(components_directory).to_i rescue DateTime.now.to_i)
      result = @app.call(env)
      self.class.current = nil
      return result
    end

    def check_and_initialize_rails_components_if_needed
      if initialization_required?
        lock_file_path = Rails.root.join('tmp', 'component_loader.lock')
        FileUtils.touch(lock_file_path) unless File.exists?(lock_file_path)

        Rails.logger.info "Creating file lock object #{lock_file_path}"
        exclusive_file_lock = File.new(lock_file_path)
        begin
          Rails.logger.info "Intending to exclusively lock file #{lock_file_path}"
            exclusive_file_lock.flock(File::LOCK_EX) # multi-process lock
            Rails.logger.info "Locked file exclusively #{lock_file_path}"
            load_timeout = 1 + self.class.code_loading_timeout_in_seconds *
              ('Rosie::Component'.safe_constantize.try(
                :where, component_type: %w[autoload_lib]).try(:count) || 0)
            Timeout::timeout(load_timeout) do
              if (initialization_required?) then # if still need to reinitialize after obtaining exclusive lock
                Rails.logger.info "Initializing components in #{components_directory} (timeout #{load_timeout})"
                write_components_to_files_and_initialize_rails_components
              end
            end
        rescue Exception => e
          Rails.logger.warn "Error during initalization: #{e.inspect} \n#{e.backtrace.join("\n")}"
        ensure
          exclusive_file_lock.flock(File::LOCK_UN)
          Rails.logger.info "Unlocked file #{lock_file_path}"
        end
      end
    end

    def write_components_to_files_and_initialize_rails_components
      if !'Rosie::Component'.constantize.table_exists?
        Rails.logger.info 'Components table does not exists, aborting component initialization'
        return
      end

      if ('Rosie::Component'.constantize.table_exists? && !'Rosie::Component'.constantize.exists?)
        'Rosie::ComponentTypes'.constantize.seed_db_on_first_request
      end

      if(component_write_files_required?)
        Rails.logger.info "Deleting old files (component_write_files_required)"
        FileUtils.rm_rf(components_directory)
      end
      Rails.logger.info "Initializing rails components at #{components_directory}"


      # loading components
      load_or_reload_all_components

      ### Adding component Views to application viewpaths
      ### 'Rosie::ClientController'.constantize.reset_and_prepend_component_path(components_directory)

      @@currently_loaded_components_directory = components_directory
      FileUtils.touch components_directory, :mtime => Rosie::Programmer.last_action_timestamp

      'Rosie::ClientController'.constantize.view_paths.each{|view_path| view_path.try :clear_cache}
      ActiveRecord::Base.connection.schema_cache.clear!
      Rails.application.reload_routes!
    end

    def filepath component
      components_directory.join 'Rosie::ComponentTypes'.constantize.relative_filepath(component)
    end

    def load_or_reload_all_components
      'Rosie::Component'.constantize.all.each{ |c|
        try_remove_defined_constants c}.each{ |c|
        write_component_to_file c}.each {|c|
        load_or_reload c }
    end

    def try_remove_defined_constants component
      component_filepath = filepath(component)
      if component.component_type.in?(%w[autoload_lib])
        klass_name = component.path.split('/').map(&:camelcase).join('')
        "Rosie".safe_constantize.try(:send, :remove_const, klass_name) rescue nil
      end
    end

    def write_component_to_file component
      component_filepath = filepath(component)
      Rails.logger.info "Loading/reloading #{component.path} (#{component_filepath})"

      FileUtils.mkdir_p(File.dirname component_filepath)
      File.write(component_filepath, component.body)

      # TODO: remove this workaround when layouts with absolute paths can be used for rendering
      if component.component_type == 'layout'
        component_filepath = component_filepath.sub(components_directory.to_s,
          components_directory.join('layouts').to_s)
        FileUtils.mkdir_p(File.dirname component_filepath)
        File.write(component_filepath, component.body)
      end
    end

    def load_or_reload component
      component_filepath = filepath(component)
      if component.component_type.in?(%w[autoload_lib])
        Rails.logger.info("Initializing component #{component.path}")
        begin
          Timeout::timeout(self.class.code_loading_timeout_in_seconds) {
            Kernel.load(component_filepath)
          }

          autolib_class_name = "Rosie::#{component.path.split('/').map(&:camelcase).join('')}"
          unless autolib_class_name.safe_constantize
            raise "Component `#{component.path}' must define constant `#{autolib_class_name}'"
          end

          component_loaded = true
          component.update_attribute(:loading_error, nil)
          component.loading_error = nil

          Rails.logger.info "Successfully loaded source: #{component_filepath}"
        rescue Exception => e
          Rails.logger.warn %(Could not read source: #{component_filepath}
            Error: #{e.inspect}")

          error_info = { description: "#{e.class.name}: #{e.message}", backtrace: e.backtrace }.with_indifferent_access
          component.update_attribute(:loading_error, error_info)
          component.loading_error = error_info
        end
      end
    end

  end
end

Rails.application.config.middleware.use Rosie::ComponentLoaderMiddleware
