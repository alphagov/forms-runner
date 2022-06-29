class Question::Date
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Serialization
  include ActiveRecord::AttributeAssignment
  include ActiveModel::Attributes

  attribute :date, :date

  validates :date, date: true

  def attributes
    { "date" => nil }
  end

  def value
    date.strftime("%m/%d/%Y")
  end
end
