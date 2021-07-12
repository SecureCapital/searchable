class Movie < ApplicationRecord
  include Searchable::Indexation
  index_as_searchable \
    watch_fields: [:title, :summary],
    save_async: false,
    touch_on_indexation: true,
    callbacks: [:actors, :characters]

  has_many :characters, :dependent => :destroy
  has_many :actors, :through => :characters
  has_many :ratings, :dependent => :delete_all

  validates :title, :presence => true, :allow_blank => false, length: {minimum: 4, maximum: 225}
  validates :summary, :presence => true, :allow_blank => false, length: {minimum: 4, maximum: 65535}
  validates :rental_price, :allow_nil => true, numericality: {in: 0..1000}

  def generate_searchable
    [title, summary, characters.map(&:name), actors.map(&:name)]
  end

  def rating
    @rating ||= (ratings.average(:rate)||0)
  end
end
