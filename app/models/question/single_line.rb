class Question::SingleLine
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Serialization

  attr_accessor :text

  validates :text, presence: true

  def attributes
    { "text" => nil }
  end
end
