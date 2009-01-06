
require File.dirname(__FILE__) + '/test_helper'

class TransationalViewTranslationTest < Test::Unit::TestCase
  include Globalize

  fixtures :globalize_languages, :globalize_countries, :globalize_translations
  
  def setup    
    Globalize::Locale.set("en-US")
    Globalize::Locale.set_base_language("en-US")
    
    Translation.convert_to_ror2_2_conventions
  end
  
  def test_plural_with_count_variable
    Locale.set("pl-PL")
    assert_equal "1 plik", "{{count}} file" / {:count => 1}
    assert_equal "2 pliki", "{{count}} file" / {:count => 2}
    assert_equal "3 pliki", "{{count}} file" / {:count => 3}
    assert_equal "4 pliki", "{{count}} file" / {:count => 4}

    assert_equal "5 plików", "{{count}} file" / {:count => 5}
    assert_equal "8 plików", "{{count}} file" / {:count => 8}
    assert_equal "13 plików", "{{count}} file" / {:count => 13}
    assert_equal "21 plików", "{{count}} file" / {:count => 21}

    assert_equal "22 pliki", "{{count}} file" / {:count => 22}
    assert_equal "23 pliki", "{{count}} file" / {:count => 23}
    assert_equal "24 pliki", "{{count}} file" / {:count => 24}

    assert_equal "25 plików", "{{count}} file" / {:count => 25}
    assert_equal "31 plików", "{{count}} file" / {:count => 31}
  end
  
  def test_translate_with_named_param_2 # hash arg, other syntax
    Locale.set('en')
    assert_equal '3 colored toucans', '{{number}} {{adjective}} {{name}}' / {'number' => 3, 'adjective' => 'colored', 'name' => 'toucans'}
    Locale.set('it')
    assert_equal '3 tucani colorati', '{{number}} {{adjective}} {{name}}' / {'number' => 3, 'adjective' => 'colorati', 'name' => 'tucani'}
  end

  def test_multiple_variable_and_count
    Locale.set('it')
    assert_equal 'Nicola ha 1 cane', '{{name}} has {{count}} dogs' / {:name => 'Nicola', :count => 1}
    assert_equal 'Nicola ha 11 cani', '{{name}} has {{count}} dogs' / {:name => 'Nicola', :count => 11}
  end
end  