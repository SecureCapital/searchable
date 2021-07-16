require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @qi               = Searchable::QueryInterface
    @klass            = @qi::Sanitizers::Order
    @instance         = @klass.new
    @conversion_error = Searchable::QueryInterface::Exceptions::ConversionError
  end

  test "cant set ordering unless order is a hash and values ate strings" do
    assert_raises(@conversion_error) do
      @klass.sanitize!(order: 1)
    end
    assert_raises(@conversion_error) do
      @klass.sanitize!(order: {a: 1})
    end
    assert_raises(@conversion_error) do
      @klass.sanitize!(order: {a: 'asc/desc'})
    end
    assert_raises(@conversion_error) do
      @klass.sanitize!(order: {a: ' asc '})
    end
    hash = @klass.sanitize!(order: {a: 'ASC'})
    assert_equal hash.keys, [:order]
    assert_equal hash[:order], {a: 'asc'}
  end

  test "Has allowed order to QI default" do
    assert_equal @instance._allowed_ordering, @qi.allowed_ordering
  end

  test "Can restrict ordering entirely" do
    hash = @klass.sanitize!(order: {a: 'ASC'}, _allowed_ordering: :none)
    assert_equal hash, {}
  end

  test "Can restrict ordering fields" do
    hash = @klass.sanitize!(order: {a: 'ASC', b: 'DESC'}, _allowed_ordering: [:b,:c])
    assert_equal hash, {order: {b: 'desc'}}
  end
end
