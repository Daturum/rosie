module Rosie
  module ApplicationHelper
    def short_time_ago_in_words time
      time_ago_in_words(time).gsub('less than a minute', '0m').gsub('about ', '').gsub(/ hour[s]?/, 'h').
        gsub(/ minute[s]?/, 'm').gsub(/ day[s]?/, 'd').gsub(/ month[s]?/, 'm') + ' ago'
    end
  end
end
