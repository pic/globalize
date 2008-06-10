class AddDefaultTextToGlobalizeTranslations < ActiveRecord::Migration
  def self.up
    add_column :globalize_translations, :default_text, :text
  end

  def self.down
    remove_column :globalize_translations, :default_text
  end
end
