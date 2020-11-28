module Rosie
  module ApplicationHelper
    def short_time_ago_in_words time
      time_ago_in_words(time).gsub('less than a minute', '0m').gsub('about ', '').gsub(/ hour[s]?/, 'h').
        gsub(/ minute[s]?/, 'm').gsub(/ day[s]?/, 'd').gsub(/ month[s]?/, 'm') + ' ago'
    end
    def mounted_path relative_path, cache: true
      relative_path = relative_path[1..-1] if relative_path.start_with?('/')
      value_proc = Proc.new do (Rosie::Engine.routes.find_script_name({})+'/').gsub('//','/') end
      mounted_path = nil

      if cache
        mounted_path = MemoryStore.fetch_invalidate('mounted_path', true, &value_proc)
      else
        mounted_path = value_proc.call
      end
      mounted_path  + relative_path
    end
  end
end
