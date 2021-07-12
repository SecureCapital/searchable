require "test_helper"

class SearchableIndexTest < ActiveSupport::TestCase
  setup do
    @klass = Searchable::Index
  end

  test "all data has been created" do
    total_count = Movie.count + Character.count + Actor.count
    assert_equal total_count, @klass.count
  end

  test "All indexed models has been registered" do
    [Movie,Character,Actor]
    union = @klass.indexed_models.map(&:name)&['Movie','Character','Actor']
    assert_equal union.size, 3
  end

  test "Validte owner must be given" do
    @si = @klass.first
    assert @si.valid?
    @si.owner_id = Movie.maximum(:id)+1
    assert_not @si.valid?
  end

  test "Validates searchable given" do
    @si = @klass.first
    @si.searchable = ''
    assert_not @si.valid?
    @si.searchable = nil
    assert_not @si.valid?
    @si.searchable = 's'
    assert @si.valid?
  end

  test "Validates uniquness of owner on create" do
    @si = @klass.first
    @new_si = @klass.new(owner_id: @si.id, owner_type: @si.owner_type, searchable: 'Cookies!')
    assert_not @new_si.valid?
  end

  test "Searchable Index can be searched" do
    assert_respond_to @klass, :searchable_indexed?
    assert_not @klass.searchable_indexed?
    assert_respond_to @klass, :search
    assert_equal @klass.search(searchable: 'star wars').to_sql, "SELECT `searchable_indices`.* FROM `searchable_indices` WHERE ((searchable COLLATE UTF8MB4_GENERAL_CI LIKE '%star%wars%'))"
    @star_wars = Movie.search(title: 'star wars').first
    total_count = 1 + @star_wars.characters.count + @star_wars.actors.count
    assert @klass.search(searchable: 'star wars').count, total_count
  end
end
