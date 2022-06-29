class Question::PhoneNumber
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Serialization

  attr_accessor :phone_number

  validates :phone_number, presence: true

  def attributes
    { "phone_number" => nil }
  end

  def value
    phone_number
  end
end
