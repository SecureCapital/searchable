require "test_helper"

class PaginationTest < ActiveSupport::TestCase
  setup do
    @qi               = Searchable::QueryInterface
    @klass            = @qi::Sanitizers::Pagination
    @instance         = @klass.new
    @conversion_error = Searchable::QueryInterface::Exceptions::ConversionError
    @limit_error      = Searchable::QueryInterface::Exceptions::LimitError
    @offset_error     = Searchable::QueryInterface::Exceptions::OffsetError
  end

  test "has maxlimit" do
    assert_equal @instance._max_limit, @qi.max_limit
  end

  test "can set offset" do
    @instance.offset = 2
    assert_equal @instance.offset, 2
    assert_raises(@offset_error) do
      @instance.offset = -1
    end
    assert_raises(@conversion_error) do
      @instance.offset = {limit: 1}
    end
    @instance.offset = "0"
    assert_equal @instance.offset, 0
    @instance.offset = nil
    assert_nil @instance.offset
  end

  test "can set limit" do
    @instance.limit = 2
    assert_equal @instance.limit, 2
    @instance._max_limit = 5
    assert_raises(@limit_error) do
      @instance.limit = 10
    end
    assert_raises(@limit_error) do
      @instance.limit = -1
    end
    assert_raises(@limit_error) do
      @instance.limit = 0
    end
    assert_raises(@conversion_error) do
      @instance.limit = {limit: 1}
    end
    @instance.limit = "3"
    assert_equal @instance.limit, 3
    @instance.limit = nil
    assert_equal @instance.limit, @instance._max_limit
  end

  test "can set page" do
    @instance.page = 2
    assert_equal @instance.page, 2
    assert_raises(@offset_error) do
      @instance.page = 0
    end
    assert_raises(@offset_error) do
      @instance.page = -1
    end
    assert_raises(@conversion_error) do
      @instance.page = {limit: 1}
    end
    @instance.page = "3"
    assert_equal @instance.page, 3
    @instance.page = nil
    assert_nil @instance.page
  end
end
