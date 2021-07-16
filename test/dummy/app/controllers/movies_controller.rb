# No route defined, this is only uused for testing qi_build. No need for
# ActionDispatch Integration test, of the right data is returned rendeing
# should be no problem.

class MoviesController < ApplicationController
  include Searchable::QueryInterface::ControllerMethods

  def rules
    {
      _allowed_fields: Movie.column_names+['searchable'],
      _filters: {
        id: {type: :integer, is_array: true},
        rental_price: {type: :numeric, is_range: true},
        updated_at: {type: :datetime, is_range: true},
        created_at: {type: :datetime, is_range: true},
      },
      _allowed_search_fields: ['title','summary','searchable'],
      _max_limit: 1000,
    }
  end

  def chain
    Movie.with_searchable
  end

  def index
    with_qi_rescue do
      qi_build(chain: chain, params: params.fetch(:q,{}).permit!, rules: rules)
    end
  end
end
