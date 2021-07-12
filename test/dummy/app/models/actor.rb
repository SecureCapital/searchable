class Actor < ApplicationRecord
  include Searchable::Indexation
  index_as_searchable \
    watch_fields: [:name, :bio],
    save_async: false,
    touch_on_indexation: true,
    callbacks: [:movies, :characters]

  has_many :characters, :dependent => :destroy
  has_many :movies, :through => :characters
  validates :name, :presence => true, :allow_blank => false, length: {minimum: 4, maximum: 225}
  validates :bio, :presence => true, :allow_blank => false, length: {minimum: 4, maximum: 65535}
  validates :birthday, :presence => true, :allow_blank => false

  def generate_searchable
    [name, bio, characters.map(&:name), movies.map(&:title)]
  end
end
