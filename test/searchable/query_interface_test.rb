require "test_helper"

class QueryInterfaceTest < ActiveSupport::TestCase
  test "Query interface has been configured" do
    @klass = Searchable::QueryInterface
    assert_equal @klass.sanitize_fields, true
    assert_equal @klass.sanitize_search, true
    assert_equal @klass.sanitize_changed_sinze, true
    assert_equal @klass.sanitize_conditions, true
    assert_equal @klass.sanitize_tagging, true
    assert_equal @klass.sanitize_order, true
    assert_equal @klass.max_limit, 10000
    assert_equal @klass.allowed_fields, :any
    assert_equal @klass.allow_search, true
    assert_equal @klass.allowed_tags_on, :any
  end
end
