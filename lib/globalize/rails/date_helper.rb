require "date"
require 'action_view/helpers/tag_helper'

module ActionView
  module Helpers
    # The Date Helper primarily creates select/option tags for different kinds of dates and date elements. All of the select-type methods
    # share a number of common options that are as follows:
    #
    # * <tt>:prefix</tt> - overwrites the default prefix of "date" used for the select names. So specifying "birthday" would give
    #   birthday[month] instead of date[month] if passed to the select_month method.
    # * <tt>:include_blank</tt> - set to true if it should be possible to set an empty date.
    # * <tt>:discard_type</tt> - set to true if you want to discard the type part of the select name. If set to true, the select_month
    #   method would use simply "date" (which can be overwritten using <tt>:prefix</tt>) instead of "date[month]".
    module DateHelper # :nodoc:
      include ActionView::Helpers::TagHelper
      DEFAULT_PREFIX = 'date' unless const_defined?('DEFAULT_PREFIX')
      
      # Reports the approximate distance in time between two Time or Date objects or integers as seconds.
      # Set <tt>include_seconds</tt> to true if you want more detailed approximations when distance < 1 min, 29 secs
      # Distances are reported based on the following table:
      #
      #   0 <-> 29 secs                                                             # => less than a minute
      #   30 secs <-> 1 min, 29 secs                                                # => 1 minute
      #   1 min, 30 secs <-> 44 mins, 29 secs                                       # => [2..44] minutes
      #   44 mins, 30 secs <-> 89 mins, 29 secs                                     # => about 1 hour
      #   89 mins, 29 secs <-> 23 hrs, 59 mins, 29 secs                             # => about [2..24] hours
      #   23 hrs, 59 mins, 29 secs <-> 47 hrs, 59 mins, 29 secs                     # => 1 day
      #   47 hrs, 59 mins, 29 secs <-> 29 days, 23 hrs, 59 mins, 29 secs            # => [2..29] days
      #   29 days, 23 hrs, 59 mins, 30 secs <-> 59 days, 23 hrs, 59 mins, 29 secs   # => about 1 month
      #   59 days, 23 hrs, 59 mins, 30 secs <-> 1 yr minus 1 sec                    # => [2..12] months
      #   1 yr <-> 2 yrs minus 1 secs                                               # => about 1 year
      #   2 yrs <-> max time or date                                                # => over [2..X] years
      #
      # With <tt>include_seconds</tt> = true and the difference < 1 minute 29 seconds:
      #   0-4   secs      # => less than 5 seconds
      #   5-9   secs      # => less than 10 seconds
      #   10-19 secs      # => less than 20 seconds
      #   20-39 secs      # => half a minute
      #   40-59 secs      # => less than a minute
      #   60-89 secs      # => 1 minute
      #
      # ==== Examples
      #   from_time = Time.now
      #   distance_of_time_in_words(from_time, from_time + 50.minutes)        # => about 1 hour
      #   distance_of_time_in_words(from_time, 50.minutes.from_now)           # => about 1 hour
      #   distance_of_time_in_words(from_time, from_time + 15.seconds)        # => less than a minute
      #   distance_of_time_in_words(from_time, from_time + 15.seconds, true)  # => less than 20 seconds
      #   distance_of_time_in_words(from_time, 3.years.from_now)              # => over 3 years
      #   distance_of_time_in_words(from_time, from_time + 60.hours)          # => about 3 days
      #   distance_of_time_in_words(from_time, from_time + 45.seconds, true)  # => less than a minute
      #   distance_of_time_in_words(from_time, from_time - 45.seconds, true)  # => less than a minute
      #   distance_of_time_in_words(from_time, 76.seconds.from_now)           # => 1 minute
      #   distance_of_time_in_words(from_time, from_time + 1.year + 3.days)   # => about 1 year
      #   distance_of_time_in_words(from_time, from_time + 4.years + 15.days + 30.minutes + 5.seconds) # => over 4 years
      #
      #   to_time = Time.now + 6.years + 19.days
      #   distance_of_time_in_words(from_time, to_time, true)     # => over 6 years
      #   distance_of_time_in_words(to_time, from_time, true)     # => over 6 years
      #   distance_of_time_in_words(Time.now, Time.now)           # => less than a minute
      #
      def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time = to_time.to_time if to_time.respond_to?(:to_time)
        distance_in_minutes = (((to_time - from_time).abs)/60).round
        distance_in_seconds = ((to_time - from_time).abs).round
 
        case distance_in_minutes
          when 0..1
            return (distance_in_minutes==0) ? 'less than a minute'.t : ('%d minutes' / 1) unless include_seconds
            case distance_in_seconds
              when 0..4 then 'less than %d seconds' / 5
              when 5..9 then 'less than %d seconds' / 10
              when 10..19 then 'less than %d seconds' / 20
              when 20..39 then 'half a minute'.t
              when 40..59 then 'less than a minute'.t
              else '%d minutes' / 1
            end
 
          when 2..44           then '%d minutes' / distance_in_minutes
          when 45..89          then 'about %d hours' / 1
          when 90..1439        then 'about %d hours' / (distance_in_minutes.to_f / 60.0).round
          when 1440..2879      then '%d days' / 1
          when 2880..43199     then 'about %d days' / (distance_in_minutes.to_f / 1440.0).round
          when 43200..86399    then 'about %d months' / 1
          when 86400..525959   then 'about %d months' / (distance_in_minutes.to_f / 43200.0).round
          when 525960..1051919 then 'about %d years' / 1
          else                 'over %d years' / (distance_in_minutes.to_f / 525960.0).round
        end
      end

    end  
      
    class DateTimeSelector
      private
        # Returns translated month names
        #  => [nil, "January", "February", "March",
        #           "April", "May", "June", "July",
        #           "August", "September", "October",
        #           "November", "December"]
        #
        # If :use_short_month option is set
        #  => [nil, "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        #           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        def translated_month_names
          month_names = @options[:use_short_month] ? 
            Date::ABBR_MONTHNAMES.map {|m| "#{m} [abbreviated month]".t(m) } : 
            Date::MONTHNAMES.map {|m| "#{m} [month]".t(m) }
          month_names.unshift(nil) if month_names.size < 13
          month_names
        end
      
    end
  end
end
