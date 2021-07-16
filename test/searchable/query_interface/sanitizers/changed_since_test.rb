require "test_helper"

class ChangedSinceTest < ActiveSupport::TestCase
  setup do
    @klass = Searchable::QueryInterface::Sanitizers::ChangedSince
    @instance = @klass.new
    @conversion_error = Searchable::QueryInterface::Exceptions::ConversionError
  end

  test "changed sinze sanitizer has field set updated_at" do
    assert_equal @instance.field_set, [:updated_at]
  end

  test "changed sinze sanitizer can set updated at" do
    @instance.updated_at = "2021-01-01 00:00:00 UTC"
    assert_equal @instance.updated_at, DateTime.new(2021,1,1,0,0,0)
    # @instance.updated_at = DateTime.new(2021,1,1,0,0,0)
    # assert_equal @instance.updated_at, DateTime.new(2021,1,1,0,0,0)
  end

  test "changed sinze sanitizer do not accept datetimes" do
    assert_raises(@conversion_error) do
      @instance.updated_at = DateTime.new(2021,1,1,0,0,0)
    end
  end

  test "changed sinze sanitizer do accept nil" do
    @instance.updated_at = nil
    assert_nil @instance.updated_at
  end

  test "changed sinze sanitizer do not accept numbers" do
    assert_raises(@conversion_error) do
      @instance.updated_at = 1
    end
  end

  test "changed sinze sanitizer do not accept invalid formats" do
    assert_raises(@conversion_error) do
      @instance.updated_at = "not a date time"
    end
  end

  test "changed_sinze has no ruleset" do
    assert_equal @instance.rule_set, []
  end

  test "changed_sinze can sanitize" do
    hash = @klass.sanitize!(updated_at: '2021-01-01 00:00:00')
    assert_equal hash.keys, [:updated_at]
    assert_equal hash[:updated_at], DateTime.new(2021,1,1,0,0,0)
  end
end
