require File.dirname(__FILE__) + '/test_helper'

class ValidationTest < Test::Unit::TestCase
  include Globalize

  fixtures :globalize_languages, :globalize_countries, 
    :globalize_translations, :globalize_products

  class Product < ActiveRecord::Base
    set_table_name "globalize_products"

    validates_length_of :name, :minimum => 5
    validates_length_of :specs, :maximum => 10

    validates_presence_of :code
  end

  def setup
    Globalize::Locale.set("he-IL")
  end

  def test_max_validation
    prod = Product.find(2)
    assert !prod.valid?
    assert_equal "המפרט ארוך מדי (המקסימום הוא 10 תווים)", prod.errors.full_messages[1]

    prod = Product.find(3)
    assert !prod.valid?
    assert_equal "Name is too short (minimum is 5 characters)", prod.errors.full_messages.first 
  end
  
  def test_on_1
    Globalize::Locale.set("it")
    prod = Product.find(2)
    assert !prod.valid?
    assert_equal "è troppo lungo (il massimo è 10 caratteri)", prod.errors.on(:specs)
  end
  
  def test_on_2
    prod = Product.new :specs => 'abcdefg', :name => 'abcdef'
    assert !prod.valid?
    assert_equal "can't be blank", prod.errors.on(:code)
  end
end
