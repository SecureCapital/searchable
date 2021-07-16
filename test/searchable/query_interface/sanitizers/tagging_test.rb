require "test_helper"

class TaggingTest < ActiveSupport::TestCase
  setup do
    @qi                 = Searchable::QueryInterface
    @klass              = @qi::Sanitizers::Tagging
    @instance           = @klass.new
    @conversion_error   = @qi::Exceptions::ConversionError
    @prohib_field_error = @qi::Exceptions::ProhibitedFieldError
  end

  test "has allowed tags on set to any" do
    assert_equal @instance._allowed_tags_on, :any
  end

  test "Can sanitize" do
    hash = @klass.sanitize!(
      tags: ['gender','studies'],
      on: 'genre',
      any: true,
      match_all: false,
      exclude: false,
      _allowed_tags_on: ['genre'],
    )
    assert_instance_of Hash, hash
    tagged = hash[:tagged]
    assert_instance_of Hash, tagged
    assert_equal (tagged.keys&%i(tags on any match_all exclude)).length, tagged.keys.length
    assert_equal tagged[:tags], ['gender','studies']
    assert_equal tagged[:on], 'genre'
    assert_equal tagged[:any], true
    assert_equal tagged[:exclude], false
    assert_equal tagged[:match_all], false
  end

  test "Can resrrict allowed tags on" do
    assert_raises(@prohib_field_error) do
      hash = @klass.sanitize!(
        tags: ['gender','studies'],
        on: 'genre',
        _allowed_tags_on: :none,
      )
    end
    assert_raises(@prohib_field_error) do
      @klass.sanitize!(
        tags: ['gender','studies'],
        on: 'title',
        _allowed_tags_on: ['genre'],
      )
    end
  end

  test "Can set boolean values" do
    @instance.any = true
    assert @instance.any
    @instance.any = '1'
    assert @instance.any
    @instance.any = 'true'
    assert @instance.any
    @instance.any = 1
    assert @instance.any

    @instance.any = false
    assert_not @instance.any
    @instance.any = '0'
    assert_not @instance.any
    @instance.any = 'false'
    assert_not @instance.any
    @instance.any = 0
    assert_not @instance.any

    assert_raises(@conversion_error) do
      @instance.any = 23
    end
  end
end
