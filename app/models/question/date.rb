class Question::Date < Question::ApplicationQuestion
  include ActiveRecord::AttributeAssignment

  attribute :date, :date
  validates :date, date: true

  def show_answer
    date&.strftime("%m/%d/%Y")
  end
end
