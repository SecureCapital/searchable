class Character < ApplicationRecord
  include Searchable::Indexation
  index_as_searchable \
    watch_fields: [:name],
    save_async: false,
    touch_on_indexation: true,
    callbacks: [:movie, :actor],
    strippers: [:compress]

  belongs_to :movie, :optional => false
  belongs_to :actor, :optional => false
  validates :name, :presence => true, :allow_blank => false, length: {minimum: 4, maximum: 225}

  def generate_searchable
    [name, actor.name, movie.title]
  end
end
