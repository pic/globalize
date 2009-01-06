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

      # Returns a select tag with options for each of the months January through December with the current month selected.
      # The month names are presented as keys (what's shown to the user) and the month numbers (1-12) are used as values
      # (what's submitted to the server). It's also possible to use month numbers for the presentation instead of names --
      # set the <tt>:use_month_numbers</tt> key in +options+ to true for this to happen. If you want both numbers and names,
      # set the <tt>:add_month_numbers</tt> key in +options+ to true. If you would prefer to show month names as abbreviations,
      # set the <tt>:use_short_month</tt> key in +options+ to true. If you want to use your own month names, set the
      # <tt>:use_month_names</tt> key in +options+ to an array of 12 month names. Override the field name using the 
      # <tt>:field_name</tt> option, 'month' by default.
      #
      # ==== Examples
      #   # Generates a select field for months that defaults to the current month that
      #   # will use keys like "January", "March".
      #   select_month(Date.today)
      #
      #   # Generates a select field for months that defaults to the current month that
      #   # is named "start" rather than "month"
      #   select_month(Date.today, :field_name => 'start')
      #
      #   # Generates a select field for months that defaults to the current month that
      #   # will use keys like "1", "3".       
      #   select_month(Date.today, :use_month_numbers => true)
      #
      #   # Generates a select field for months that defaults to the current month that
      #   # will use keys like "1 - January", "3 - March".
      #   select_month(Date.today, :add_month_numbers => true)
      #
      #   # Generates a select field for months that defaults to the current month that
      #   # will use keys like "Jan", "Mar".
      #   select_month(Date.today, :use_short_month => true)
      #
      #   # Generates a select field for months that defaults to the current month that
      #   # will use keys like "Januar", "Marts."
      #   select_month(Date.today, :use_month_names => %w(Januar Februar Marts ...))
      #
      def select_month(date, options = {}, html_options = {})
        val = date ? (date.kind_of?(Fixnum) ? date : date.month) : ''
        if options[:use_hidden]
          hidden_html(options[:field_name] || 'month', val, options)
        else
          month_options = []
          month_names = options[:use_month_names] || (options[:use_short_month] ? 
            Date::ABBR_MONTHNAMES.map {|m| "#{m} [abbreviated month]".t(m) } : 
            Date::MONTHNAMES.map {|m| "#{m} [month]".t(m) }
            )
          month_names.unshift(nil) if month_names.size < 13
          1.upto(12) do |month_number|
            month_name = if options[:use_month_numbers]
              month_number
            elsif options[:add_month_numbers]
              month_number.to_s + ' - ' + month_names[month_number]
            else
              month_names[month_number]
            end

            month_options << ((val == month_number) ?
              content_tag(:option, month_name, :value => month_number, :selected => "selected") :
              content_tag(:option, month_name, :value => month_number)
            )
            month_options << "\n"
          end
          select_html(options[:field_name] || 'month', month_options.join, options, html_options)
        end
      end 
      
      def select_html(type, html_options, options, select_tag_options = {})
        name_and_id_from_options(options, type)
        select_options = {:id => options[:id], :name => options[:name]}
        select_options.merge!(:disabled => 'disabled') if options[:disabled]
        select_options.merge!(select_tag_options) unless select_tag_options.empty?
        select_html = "\n"
        select_html << content_tag(:option, '', :value => '') + "\n" if options[:include_blank]
        select_html << html_options.to_s
        content_tag(:select, select_html, select_options) + "\n"
      end
      
      def name_and_id_from_options(options, type)
        options[:name] = (options[:prefix] || DEFAULT_PREFIX) + (options[:discard_type] ? '' : "[#{type}]")
        options[:id] = options[:name].gsub(/([\[\(])|(\]\[)/, '_').gsub(/[\]\)]/, '')
      end
    end
  end
end
