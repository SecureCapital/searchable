class Rating < ApplicationRecord
  belongs_to :movie, :optional => false
  validates :rate, :presence => true, :allow_blank => false, numericality: { only_integer: true, in: 0..10}
end
