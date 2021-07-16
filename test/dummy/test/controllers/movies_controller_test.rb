require "test_helper"

class MoviesControllerTest < ActiveSupport::TestCase
  test "can build a search" do
    cc = MoviesController.new
    cc.params = {
      q: {
        where: {
          rental_price: '0..200',
        },
        search: {
          default: 'droid'
        },
      }
    }
    res = cc.index
    assert_instance_of Hash, res
    assert res.keys.exclude?(:error)
    assert_equal res[:count], 1
    assert_equal res[:limit], cc.rules[:_max_limit]
    assert_equal res[:page], 1
    assert_equal res[:data][0], Movie.find_by(title: "Star Wars: Episode IV - A New Hope")
  end

  test "Will return error on bad params" do
    cc = MoviesController.new
    cc.params = {
      q: {
        where: {
          rental_price: 'expensive!'
        }
      }
    }
    res = cc.index
    assert_instance_of Hash, res
    assert res.keys.include?(:error)
  end
end
