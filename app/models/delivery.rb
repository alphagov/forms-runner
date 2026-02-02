class Delivery < ApplicationRecord
  has_many :submission_deliveries, dependent: :destroy
  has_many :submissions, through: :submission_deliveries
end
