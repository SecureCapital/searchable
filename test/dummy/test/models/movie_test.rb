require "test_helper"

class MovieTest < ActiveSupport::TestCase
  setup do
    @movies = Movie.all.to_a
    @movie = @movies.first
  end

  test "movies exists" do
    assert @movies.size > 0
  end

  test "Basic movie assertions (data set up and working)" do
    assert_respond_to @movie, :actors
    assert @movie.actors.count > 0
    assert_respond_to @movie, :ratings
    assert @movie.ratings.count > 0
    assert_respond_to @movie, :rating
    assert (@movie.rating >= 0) && (@movie.rating <= 10)
    assert_respond_to @movie, :rental_price
    assert (@movie.rental_price >= 0) && (@movie.rental_price <= 1000)
    assert @movies.all?(&:valid?)
  end

  test "movie has included indexation" do
    assert_respond_to @movie, :searchable
    assert_respond_to Movie, :search
  end

  test "movie has_one serachable_index" do
    assert_respond_to @movie, :searchable_index
    reflection = Movie.reflect_on_all_associations.find{|reflection| reflection.name==:searchable_index}
    assert !reflection.blank?
    assert reflection.has_one?
  end

  test "All movies has a searchable indx, creqated on seed" do
    assert @movies.all?{|mv| mv.searchable_index.id}
  end

  test "movies searchable index has been configured" do
    assert_equal Movie.searchable_watch_fields, [:title, :summary]
    assert_equal Movie.searchable_save_async?, false
    assert_equal Movie.searchable_touch_on_indexation?, true
    assert_equal Movie.searchable_callbacks, [:actors, :characters]
    assert_equal Movie.searchable_indexed?, true

    Movie.searchable_watch_fields = [:title]
    assert_equal Movie.searchable_watch_fields, [:title]
    Movie.searchable_watch_fields = [:title, :summary]
  end

  test "configuration is not on instance" do
    assert_not @movie.respond_to? :searchable_watch_fields
    assert_nil @movie.instance_variable_get("@searchable_watch_fields")
  end

  test "movie has searchable_columns" do
    assert_equal Movie.searchable_columns, ['title', 'summary']
  end

  test "movie can generate raw search string" do
    arr = @movie.generate_searchable
    assert_instance_of Array, arr
    assert_equal arr.size, 4
    assert_includes arr, @movie.title
    assert_includes arr, @movie.summary
    assert_includes arr, @movie.characters.map(&:name)
    assert_includes arr, @movie.actors.map(&:name)
  end

  test "movie can return searchable text" do
    assert_respond_to @movie, :searchable
    assert_instance_of String, @movie.searchable
    assert_instance_of Searchable::Index, @movie.searchable_index
    assert_equal @movie.searchable =~ /star wars/, 0
  end

  test "has valid searchable index" do
    @movie.searchable_index.destroy if @movie.searchable_index
    @movie.build_searchable_index
    assert_not @movie.searchable_index.valid?
    @movie.set_searchable
    assert @movie.searchable_index.valid?
  end

  test "returns searchable_changed true when new index" do
    if @movie.searchable_index
      @movie.searchable_index.destroy
      @movie.reload
    end
    assert @movie.searchable_should_change?
  end

  test "can save searchable index synchroneously" do
    @movie.save_searchable_sync
    updates = [@movie.searchable_index.updated_at] + Movie.searchable_callbacks.map do |meth|
      @movie.send(meth).map{|rec| rec.searchable_index.updated_at}
    end.flatten
    assert_equal updates.compact.size, @movie.actors.size+@movie.characters.size+1
  end

  test "Searchable changed false until attr save" do
    @movie.save
    @movie.reload
    assert_not @movie.searchable_should_change?
    @movie.rental_price += 1
    assert @movie.rental_price_changed?
    update = @movie.searchable_index.updated_at
    @movie.save
    assert @movie.saved_change_to_rental_price?
    assert_equal @movie.searchable_index.updated_at, update
    @movie.title = 'Star Wars - the rampage of Walt Disney'
    assert @movie.title_changed?
    assert_not @movie.searchable_should_change?
    update = @movie.searchable_index.updated_at
    assert @movie.save
    assert (@movie.searchable_index.searchable =~ /Star Wars rampage Walt Disney.*/i) == 0
  end

  test "Will save searchable on create" do
    # Norice that async is false, will not asser when async is true
    @movie = Movie.new(title: 'Funny Film', summary: "Beleive you me this is a funny film!")
    assert @movie.save
    assert_not @movie.searchable_index.updated_at.nil?
  end

  test "Movie class ahas searchable columns title and summary" do
    assert (Movie.searchable_columns&['title','summary']).length == 2
  end

  test "Movie has a searchable field scop concatenating title and summary" do
    assert Movie.searchable_field_scope(column_name: 'special_search').all? do |mv|
      (mv.title + ' ' + mv.summary) == mv.special_search
    end
  end

  test "Movie can join searchable_index" do
    assert Movie.join_searchable_index.to_sql == "SELECT `movies`.* FROM `movies` LEFT JOIN `searchable_indices` ON `searchable_indices`.`owner_id` = `movies`.`id` AND `searchable_indices`.`owner_type` = 'Movie'"
  end

  test "Can join with searchable and including data to attributes" do
    mv = Movie.with_searchable.first
    assert mv.attributes.keys.include?('searchable')
    assert_instance_of String, mv.attributes['searchable']
  end

  test "Can search movies without searchable" do
    assert Movie.search(title: 'star').to_sql == "SELECT `movies`.* FROM `movies` WHERE ((title COLLATE UTF8MB4_GENERAL_CI LIKE '%star%'))"
    assert Movie.search(title: 'star', fuzzy: false).to_sql == "SELECT `movies`.* FROM `movies` WHERE ((title COLLATE UTF8MB4_GENERAL_CI LIKE 'star'))"
    assert Movie.search(title: 'star', summary: 'jones').to_sql == "SELECT `movies`.* FROM `movies` WHERE ((title COLLATE UTF8MB4_GENERAL_CI LIKE '%star%') OR (summary COLLATE UTF8MB4_GENERAL_CI LIKE '%jones%'))"
    assert Movie.search(title: 'star', summary: 'jones', join: 'AND').to_sql == "SELECT `movies`.* FROM `movies` WHERE ((title COLLATE UTF8MB4_GENERAL_CI LIKE '%star%') AND (summary COLLATE UTF8MB4_GENERAL_CI LIKE '%jones%'))"
    assert Movie.search(title: 'star wars').count == 1
  end

  test "Can search movies with searchable" do
    assert_equal Movie.with_searchable.search(searchable: 'star').to_sql, "SELECT `movies`.*, `searchable_indices`.`searchable` as `searchable` FROM `movies` LEFT JOIN `searchable_indices` ON `searchable_indices`.`owner_id` = `movies`.`id` AND `searchable_indices`.`owner_type` = 'Movie' WHERE ((searchable COLLATE UTF8MB4_GENERAL_CI LIKE '%star%'))"
    assert_equal Movie.with_searchable.search(searchable: 'star').count(:all), 1
    assert_equal Movie.join_searchable_index.search(searchable: 'star').to_sql, "SELECT `movies`.* FROM `movies` LEFT JOIN `searchable_indices` ON `searchable_indices`.`owner_id` = `movies`.`id` AND `searchable_indices`.`owner_type` = 'Movie' WHERE ((searchable COLLATE UTF8MB4_GENERAL_CI LIKE '%star%'))"
    assert_equal Movie.join_searchable_index.search(searchable: 'star').count, 1
    assert_equal Movie.join_searchable_index.search(searchable: 'star', title: 'Indiana Jones', join: 'AND').to_sql, "SELECT `movies`.* FROM `movies` LEFT JOIN `searchable_indices` ON `searchable_indices`.`owner_id` = `movies`.`id` AND `searchable_indices`.`owner_type` = 'Movie' WHERE ((searchable COLLATE UTF8MB4_GENERAL_CI LIKE '%star%') AND (title COLLATE UTF8MB4_GENERAL_CI LIKE '%Indiana%Jones%'))"
    assert_equal Movie.join_searchable_index.search(searchable: 'star', title: 'Indiana Jones', join: 'AND').count, 0
    assert_equal Movie.join_searchable_index.search(searchable: 'star', title: 'Indiana Jones', join: 'OR').count, 2
  end
end
