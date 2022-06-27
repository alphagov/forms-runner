class Question::Email
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Serialization

  attr_accessor :email

  validates :email, presence: true

  def attributes
    { "email" => nil }
  end
end
