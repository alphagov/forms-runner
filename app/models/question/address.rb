class Question::Address < Question::ApplicationQuestion
  attribute :address1
  attribute :address2
  attribute :city
  attribute :postcode

  validates :address1, presence: true
  validates :city, presence: true
  validates :postcode, presence: true
end
