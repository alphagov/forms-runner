class Question::Address
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Serialization

  attr_accessor :address1, :address2, :city, :postcode

  validates :address1, presence: true
  validates :city, presence: true
  validates :postcode, presence: true

  def attributes
    { "address1" => nil, "address2" => nil, "city" => nil, "postcode" => nil }
  end
end
