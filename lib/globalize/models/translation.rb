module Globalize # :nodoc:
  class Translation < ActiveRecord::Base  # :nodoc:
    set_table_name "globalize_translations"    

    def self.reloadable?; false end

    belongs_to :language
    
    def self.convert_to_ror2_2_conventions
      do_conversion = lambda do |a| 
        ts = Translation.find :all, :conditions => ["#{a} like ?", '%%%d%'] # .*%d.*
        ts.each do |t| 
          n_a = t.send(a).sub('%d', '{{count}}')
          t.update_attribute(a, n_a)
        end  
        ts = Translation.find :all, :conditions => ["#{a} like ?", '%%%{%}%'] # .*%\{.*\}.*
        ts.each do |t| 
          n_a = t.send(a).gsub(/%\{(.*?)\}/, '{{\1}}')
          t.update_attribute(a, n_a)
        end
        "#{a} converted"
      end
      %w(tr_key text).each do |a|
        logger.info do_conversion.call(a)
      end
      logger.info((do_conversion.call('default_text') rescue 'default_text missing')) 
    end
  end
end
