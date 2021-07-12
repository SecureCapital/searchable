require "test_helper"

class SearchableTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Searchable::VERSION
  end

  test "searchable has configuration" do
    assert_instance_of OpenStruct, Searchable.config
    assert_respond_to Searchable.config, :searchable_data_types
    assert_respond_to Searchable.config, :latency
    assert_respond_to Searchable.config, :callback_latency
    assert_respond_to Searchable.config, :collate_function
    assert_respond_to Searchable.config, :locale
    assert_respond_to Searchable.config, :fill_words_en
  end

  test "searchable can be configured" do
    assert_respond_to Searchable, :configure
    Searchable.configure do |config|
      config.data_types = 'Flunk and Funk'
    end
    assert_respond_to Searchable.config, :data_types
    assert_equal Searchable.config.data_types, 'Flunk and Funk'
    assert_respond_to Searchable, :data_types
  end

  test "srarchable has config class methods after configuration" do
    assert_respond_to Searchable, :searchable_data_types
    assert_respond_to Searchable, :latency
    assert_respond_to Searchable, :callback_latency
    assert_respond_to Searchable, :collate_function
    assert_respond_to Searchable, :locale
    assert_respond_to Searchable, :fill_words_en
  end
end
