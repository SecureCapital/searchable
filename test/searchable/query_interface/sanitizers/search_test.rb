require "test_helper"

class SearchTest < ActiveSupport::TestCase
  setup do
    @qi                 = Searchable::QueryInterface
    @klass              = @qi::Sanitizers::Search
    @conversion_error   = @qi::Exceptions::ConversionError
    @prohib_field_error = @qi::Exceptions::ProhibitedFieldError
  end

  test "can sanitize" do
    hash = @klass.sanitize!(default: 'luke')
    assert_equal hash.keys, [:search]
    assert_equal hash[:search], {searchable: 'luke', fuzzy: true, join: 'OR'}
  end

  test "can search multiple fields" do
    hash = @klass.sanitize!(searchable: 'luke', title: 'star')
    assert_equal hash.keys, [:search]
    assert_equal hash[:search], {searchable: 'luke', fuzzy: true, join: 'OR', title: 'star'}
  end

  test "Can set arguments" do
    hash = @klass.sanitize!(searchable: '%luke%', title: 'star%', join: 'AND', fuzzy: false)
    assert_equal hash.keys, [:search]
    assert_equal hash[:search], {searchable: '%luke%', fuzzy: false, join: 'AND', title: 'star%'}
  end

  test "Can disallow search" do
    hash = @klass.sanitize!(default: 'luke', _allow_search: false)
    assert_equal hash, {}
  end

  test "Can restrict search fields" do
    hash = @klass.sanitize!(default: 'luke', _allowed_search_fields: [])
    assert_equal hash, {search: {searchable: 'luke', join: 'OR', fuzzy: true}}
    assert_raises(@prohib_field_error) do
      @klass.sanitize!(title: 'luke', _allowed_search_fields: [])
    end
  end

  test "Canot search on none strings" do
    hash = @klass.sanitize!(default: nil)
    assert_equal hash, {search: {join: 'OR', fuzzy: true}}

    assert_raises(@conversion_error) do
      @klass.sanitize!(title: 789)
    end
  end
end
