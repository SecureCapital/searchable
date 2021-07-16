require "test_helper"

class SearchableIndexWorkerTest < ActiveSupport::TestCase #ActionDispatch::IntegrationTest
  setup do
    @klass = Searchable::IndexWorker
    @siw = @klass.new
    @movie = Movie.first
    @siw.instance_variable_set("@id", @movie.id)
    @siw.instance_variable_set("@klass", 'Movie')
    @siw.instance_variable_set("@callback", 'characters')
    @siw.instance_variable_set("@call", 'set_searchable')
  end

  test "Searchable index worker can find data instance " do
    assert_equal @siw.item, @movie
  end

  test "searchable index worker kan set searchable" do
    assert @siw.set_searchable
  end

  # async
  # test "searchable index worker can set callback data" do
  #   characters = @movie.characters
  #   assert_equal @siw.set_searchable_on_callback, characters
  # end
  
  test "searchable index worker kan perform" do
    assert @siw.perform(call: :set_searchable)
  end

  # Notice there has been no test of the models will in fact do async updates!
  # Sidekiq is plentily tested so we rely on no spelling mistake on sync call!
end
