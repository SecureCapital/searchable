require "test_helper"

class SanitizersTest < ActiveSupport::TestCase
  test "can sanitize params with rules" do
    params = {
      where: {
        rental_price: "25..50",
        title: ['Star Wars','Witness'],
        unpermitted_param: '10',
      },
      where_not: {
        date: '..2021-01-01',
        unpermitted_param: '10',
      },
      or: {
        type: "Animation",
        unpermitted_param: '10',
      },
      or_not: {
        id: "5..10",
        unpermitted_param: '10',
      },
      order: {
        updated_at: 'desc'
      },
      limit: 5,
      page: 2,
      offset: 5,
      fields: ['title','summary','searchable'],
      search: {
        title: 'Star',
        default: 'luke',
        join: 'AND',
      },
      updated_at: '2021-01-01 00:00:00 UTC',
      tagged: {
        tags: ['cookie','monster'],
        on: 'type',
        match_all: true,
      }
    }

    rules = {
      :_filters => {
        :rental_price => {type: :numeric,  is_range: true},
        :title => {type: :string, is_array: true},
        :date => {type: :date, is_range: true},
        :type => {type: :string, is_array: true},
        :id => {type: :integer, is_range: true}
      },
      :_allow_xor => false
    }

    hash = Searchable::QueryInterface::Sanitizers.sanitize!(params,rules)
    expected_result = {
      :fields=>["title", "summary", "searchable"],
      :search=>{:join=>"AND", :fuzzy=>true, :title=>"Star", :searchable=>"luke"},
      :updated_at=>DateTime.new(2021,1,1,0,0,0),
      :where=>{:rental_price=>25.0..50.0, :title=>["Star Wars", "Witness"]},
      :where_not=>{:date=>(-Date::Infinity.new)..Date.new(2021,1,1)},
      # :xor=>{:type=>"Animation"},
      :xor_not=>{:id=>5..10},
      :tagged=>{:tags=>["cookie", "monster"], :on=>"type", :match_all=>true},
      :limit=>5,
      :offset=>5,
      :page=>2,
      :order=>{:updated_at=>"desc"}
    }

    assert_equal hash, expected_result
  end
end
