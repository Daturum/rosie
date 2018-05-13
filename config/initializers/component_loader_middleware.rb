module Rosie
  class ComponentLoaderMiddleware

    def initialize app
      @app = app
    end

    def self.current
      RequestStore["ComponentLoaderMiddleware.current"]
    end
    def self.current= value
      RequestStore["ComponentLoaderMiddleware.current"] = value
    end

    @@currently_loaded_components_directory = nil
    def components_directory # this is thread safe
      begin
        RequestStore["components_directory"] ||=
          Rails.root.join('app', 'interfaces')
      rescue # TODO: write white list of exceptions
        nil
      end
    end

    def initialization_required?
      #Rails.logger.info "Checking initialization required:\ncomponents_directory #{components_directory}\nDir.exists?(components_directory) #{Dir.exists?(components_directory)}\n@@currently_loaded_components_directory != components_directory #{@@currently_loaded_components_directory != components_directory}"
      components_directory &&                                                  # if components and programmers exist in database
        (!Dir.exists?(components_directory) ||                                   # if these components aren't written to files
        (File.mtime(components_directory).to_i != Rosie::Programmer.last_action_timestamp.to_i))    # or current loaded version is obsolete
    end

    def call env
      dup.threadsafe_call env
    end

    def threadsafe_call env
      self.class.current = self
      Rails.logger.info "currently_loaded_components_directory: #{@@currently_loaded_components_directory}"
      check_and_initialize_rails_components_if_needed(env)
      result = @app.call(env)
      self.class.current = nil
      return result
    end

    def check_and_initialize_rails_components_if_needed(env)
      if initialization_required?
        lock_file_path = Rails.root.join('tmp', 'component_loader.lock')
        FileUtils.touch(lock_file_path) unless File.exists?(lock_file_path)

        Rails.logger.info "Creating file lock object #{lock_file_path}"
        exclusive_file_lock = File.new(lock_file_path)
        begin
          Rails.logger.info "Intending to exclusively lock file #{lock_file_path}"
          exclusive_file_lock.flock(File::LOCK_EX) # multi-process lock
          Rails.logger.info "Locked file exclusively #{lock_file_path}"
          if (initialization_required?) then # if still need to reinitialize after obtaining exclusive lock
            Rails.logger.info "Initializing components in #{components_directory}"
            write_components_to_files_and_initialize_rails_components(env)
          end
        rescue Exception => e
          Rails.logger.warn "Error during initalization: #{e.inspect} \n#{e.backtrace.join("\n")}"
        ensure
          exclusive_file_lock.flock(File::LOCK_UN)
          Rails.logger.info "Unlocked file #{lock_file_path}"
        end
      end
    end

    def write_components_to_files_and_initialize_rails_components(env)
      if ('Rosie::Component'.constantize.table_exists? && !'Rosie::Component'.constantize.exists?)
        'Rosie::ComponentTypes'.constantize.seed_db_with_first_request(Rack::Request.new(env))
      end

      if !Dir.exists?(components_directory)
        Rails.logger.info "Writing components to #{components_directory}"
        FileUtils.rm_rf(components_directory) # erasing old releases
      end
      Rails.logger.info "Initializing rails components at #{components_directory}"

      if !'Rosie::Component'.constantize.table_exists?
        Rails.logger.info 'Components table does not exists, aborting component initialization'
        return
      end

      # loading components
      'Rosie::Component'.constantize.all.each do |component| load_or_reload component end

      ### Adding component Views to application viewpaths
      ### 'Rosie::ClientController'.constantize.reset_and_prepend_component_path(components_directory)

      @@currently_loaded_components_directory = components_directory
      FileUtils.touch components_directory, :mtime => Rosie::Programmer.last_action_timestamp

  end

    def filepath component
      base_dir = components_directory
      base_dir = base_dir.join('layouts') if component.component_type == 'layout'
      component_path = component.path
      if component.component_type == 'partial'
        segments = component_path.split('/')
        segments[-1] = "_#{segments[-1]}"
        component_path = segments.join('/')
      end

      base_dir.join("#{component_path}.#{component.format}.#{component.handler}").to_s.
        sub(/\.ruby$/,'.rb') #sub('.json.','.').
    end

    def load_or_reload component
      component_filepath = filepath(component)
      Rails.logger.info "Loading/reloading #{component.path} (#{component_filepath})"

      FileUtils.mkdir_p(File.dirname component_filepath)
      File.write(component_filepath, component.body)
      if component.component_type.in?(%w[controller active_job initializer])
        'Rosie::Component'.constantize.remove_defined_classnames component

        component_classname = component.defined_classname
        Rails.logger.info("Initializing component #{component.path} (classname #{component_classname})")
        component_loaded = false
        begin
          Timeout::timeout(2) { Kernel.load(component_filepath) } rescue raise("Timeout loading #{component_filepath}")
          if component.component_type.in?(%w[controller active_job]) && !component_classname.safe_constantize
            raise(TypeError, %(Component #{component_filepath} does not define class '#{component_classname}'))
          end

          component_loaded = true
          component.update_attribute(:loading_error, nil)
          component.loading_error = nil

          Rails.logger.info "Read class name: #{component_classname} ; constantized: #{
            component_classname.safe_constantize.inspect} ; source: #{component_filepath}"
        rescue Exception => e
          Rails.logger.warn %(Could not read class name: #{component_classname} ; constantized: #{
            component_classname.safe_constantize.inspect} ; source: #{component_filepath}
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
