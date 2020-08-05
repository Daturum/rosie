module Rosie
  module ApplicationHelper
    def short_time_ago_in_words time
      time_ago_in_words(time).gsub('less than a minute', '0m').gsub('about ', '').gsub(/ hour[s]?/, 'h').
        gsub(/ minute[s]?/, 'm').gsub(/ day[s]?/, 'd').gsub(/ month[s]?/, 'm') + ' ago'
    end
    def mounted_path relative_path
      relative_path = relative_path[1..-1] if relative_path.start_with?('/')
      mounted_path  = MemoryStore.fetch_invalidate('yay', true) do
        (rosie.routes.find_script_name({})+'/').gsub('//','/')
      end
      mounted_path  + relative_path
    end
  end
end
