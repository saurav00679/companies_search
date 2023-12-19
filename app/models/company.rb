class Company < ApplicationRecord
  validates :name, presence: true
  validates :location, presence: true
end
