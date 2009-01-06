module ActiveRecord # :nodoc:

  # Overrode Errors methods to handle numbers correctly for translation, and
  # to automatically translate error messages. Messages are translated after
  # the field names have been substituted.
  class Errors

    # Returns all the full error messages in an array.
    #
    #   class Company < ActiveRecord::Base
    #     validates_presence_of :name, :address, :email
    #     validates_length_of :name, :in => 5..30
    #   end
    #
    #   company = Company.create(:address => '123 First St.')
    #   company.errors.full_messages # =>
    #     ["Name is too short (minimum is 5 characters)", "Name can't be blank", "Address can't be blank"]
    def full_messages(options = {})
      full_messages = []

      @errors.each_key do |attr|
        @errors[attr].each do |message|
          next unless message
          msg = [ message ].flatten
          msg_text, msg_opt = msg
          if attr == "base"
            full_messages << msg_text / msg_opt
          else
            #key = :"activerecord.att.#{@base.class.name.underscore.to_sym}.#{attr}" 
            attr_name = @base.class.human_attribute_name(attr)
            full_messages << (attr_name + ' ' + msg_text) / msg_opt
          end
        end
      end
      return full_messages
    end 

=begin
    def full_messages # :nodoc:
      full_messages = []

      @errors.each_key do |attr|
        @errors[attr].each do |msg|
          next if msg.nil?
          msg = [ msg ].flatten
          msg_text, msg_num = msg
          if attr == "base"
            full_messages << msg_text / msg_num
          else
            full_messages <<
              (@base.class.human_attribute_name(attr) + " " + msg_text) / msg_num
          end
        end
      end

      return full_messages
    end
=end

    # Returns +nil+, if no errors are associated with the specified +attribute+.
    # Returns the error message, if one error is associated with the specified +attribute+.
    # Returns an array of error messages, if more than one error is associated with the specified +attribute+.
    #
    #   class Company < ActiveRecord::Base
    #     validates_presence_of :name, :address, :email
    #     validates_length_of :name, :in => 5..30
    #   end
    #
    #   company = Company.create(:address => '123 First St.')
    #   company.errors.on(:name)      # => ["is too short (minimum is 5 characters)", "can't be blank"]
    #   company.errors.on(:email)     # => "can't be blank"
    #   company.errors.on(:address)   # => nil
    def on(attribute)
      errors = @errors[attribute.to_s]
      return nil if errors.nil?
      txt_msgs = errors.map {|msg| msg.kind_of?(Array) ? msg.first / msg.last : msg.t }
      errors.size == 1 ? txt_msgs.first : txt_msgs
    end

=begin
    # * Returns nil, if no errors are associated with the specified +attribute+.
    # * Returns the error message, if one error is associated with the specified +attribute+.
    # * Returns an array of error messages, if more than one error is associated with the specified +attribute+.
    def on(attribute)
      if @errors[attribute.to_s].nil?
        return nil
      else
        msgs = @errors[attribute.to_s]
        txt_msgs = msgs.map {|msg| msg.kind_of?(Array) ? msg.first / msg.last : msg.first.t }
        return txt_msgs.length == 1 ? txt_msgs.first : txt_msgs
      end
    end
=end

    # Translates an error message in it's default scope (<tt>activerecord.errrors.messages</tt>).
    # Error messages are first looked up in <tt>models.MODEL.attributes.ATTRIBUTE.MESSAGE</tt>, if it's not there, 
    # it's looked up in <tt>models.MODEL.MESSAGE</tt> and if that is not there it returns the translation of the 
    # default message (e.g. <tt>activerecord.errors.messages.MESSAGE</tt>). The translated model name, 
    # translated attribute name and the value are available for interpolation.
    #
    # When using inheritence in your models, it will check all the inherited models too, but only if the model itself
    # hasn't been found. Say you have <tt>class Admin < User; end</tt> and you wanted the translation for the <tt>:blank</tt>
    # error +message+ for the <tt>title</tt> +attribute+, it looks for these translations:
    # 
    # <ol>
    # <li><tt>activerecord.errors.models.admin.attributes.title.blank</tt></li>
    # <li><tt>activerecord.errors.models.admin.blank</tt></li>
    # <li><tt>activerecord.errors.models.user.attributes.title.blank</tt></li>
    # <li><tt>activerecord.errors.models.user.blank</tt></li>
    # <li><tt>activerecord.errors.messages.blank</tt></li>
    # <li>any default you provided through the +options+ hash (in the activerecord.errors scope)</li>
    # </ol>
    def generate_message(attribute, message = :invalid, options = {})
      [I18n.translate('activerecord.errors.messages')[message], options]
=begin      
      message, options[:default] = options[:default], message if options[:default].is_a?(Symbol)

      defaults = @base.class.self_and_descendents_from_active_record.map do |klass| 
        [ :"models.#{klass.name.underscore}.attributes.#{attribute}.#{message}", 
          :"models.#{klass.name.underscore}.#{message}" ]
      end
      
      defaults << options.delete(:default)
      defaults = defaults.compact.flatten << :"messages.#{message}"

      key = defaults.shift
      value = @base.respond_to?(attribute) ? @base.send(attribute) : nil

      options = { :default => defaults,
        :model => @base.class.human_name,
        :attribute => @base.class.human_attribute_name(attribute.to_s),
        :value => value,
        :scope => [:activerecord, :errors]
      }.merge(options)

      I18n.translate(key, options)
=end
    end

  end

=begin
  module Validations # :nodoc: all
    module ClassMethods
      def validates_length_of(*attrs)
        # Merge given options with defaults.
        options = {
          :too_long     => I18n.translate('activerecord.errors.messages')[:too_long],
          :too_short    => I18n.translate('activerecord.errors.messages')[:too_short],
          :wrong_length => I18n.translate('activerecord.errors.messages')[:wrong_length]
        }.merge(DEFAULT_VALIDATION_OPTIONS)
        options.update(attrs.pop.symbolize_keys) if attrs.last.is_a?(Hash)

        # Ensure that one and only one range option is specified.
        range_options = ALL_RANGE_OPTIONS & options.keys
        case range_options.size
          when 0
            raise ArgumentError, 'Range unspecified.  Specify the :within, :maximum, :minimum, or :is option.'
          when 1
            # Valid number of options; do nothing.
          else
            raise ArgumentError, 'Too many range options specified.  Choose only one.'
        end

        # Get range option and value.
        option = range_options.first
        option_value = options[range_options.first]

        case option
        when :within, :in
          raise ArgumentError, ":#{option} must be a Range" unless option_value.is_a?(Range)

          too_short = options[:too_short]
          too_long  = options[:too_long]

          validates_each(attrs, options) do |record, attr, value|
            if value.nil? or value.size < option_value.begin
              record.errors.add(attr, too_short, option_value.begin)
            elsif value.size > option_value.end
              record.errors.add(attr, too_long, option_value.end)
            end
          end
        when :is, :minimum, :maximum
          raise ArgumentError, ":#{option} must be a nonnegative Integer" unless option_value.is_a?(Integer) and option_value >= 0

          # Declare different validations per option.
          validity_checks = { :is => "==", :minimum => ">=", :maximum => "<=" }
          message_options = { :is => :wrong_length, :minimum => :too_short, :maximum => :too_long }

          message = options[:message] || options[message_options[option]]

          validates_each(attrs, options) do |record, attr, value|
            record.errors.add(attr, message, option_value) unless !value.nil? and value.size.method(validity_checks[option])[option_value]
          end
        end
      end
    end
  end
=end
end

class ActiveRecord::Base # :nodoc:
  include Globalize::DbTranslate
end
