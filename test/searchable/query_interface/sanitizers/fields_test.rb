require "test_helper"

class FieldsTest < ActiveSupport::TestCase
  setup do
    @qi    = Searchable::QueryInterface
    @klass = @qi::Sanitizers::Fields
    @instance = @klass.new
    @conversion_error = Searchable::QueryInterface::Exceptions::ConversionError
  end

  test "sanitizers fields has rule set" do
    assert_equal @instance.rule_set, [:_required_fields, :_allowed_fields]
  end

  test "sanitizers fields has field set" do
    assert_equal @instance.field_set, [:fields]
  end

  test "sanitizers fields has allowed fields to configuration" do
    assert_equal @instance._allowed_fields, @qi.allowed_fields
  end

  test "sanitizers can set fields" do
    assert_equal @instance._allowed_fields, :any
    flds = [:title, :summary, '*', 'actors.name']
    @instance.fields = flds
    hash = @instance.to_h
    assert_equal hash.keys, [:fields]
    assert_equal hash[:fields], flds.map(&:to_s)
  end

  test "sanitizers cannot set fields from string" do
    assert_raises(@conversion_error) do
      @instance.fields = "1,2,3"
    end
  end

  test "sanitizers cannot only set strings as fields" do
    @instance.fields = [1,2,nil,{},'a',:b]
    assert_equal @instance.fields, ['a','b']
  end

  test "sanitizers fields can set allowed allowed fields" do
    hash = @klass.sanitize!(:fields => ['b','c'], :_allowed_fields => ['a','b'])
    assert_equal hash.keys, [:fields]
    assert_equal hash[:fields], ['b']
  end

  test "sanitizers fields can set allowed allowed fields with none" do
    hash = @klass.sanitize!(:fields => ['b','c'], :_allowed_fields => :none)
    assert_equal hash, {}
  end

  test "sanitizers fields can set required fields" do
    hash = @klass.sanitize!(:fields => ['b','c'], :_required_fields => ['a'])
    assert_equal hash[:fields].sort, %w(a b c)
  end
end
