class Question::Date < Question::QuestionBase
  include ActiveRecord::AttributeAssignment

  attribute :date, :date
  validates :date, date: true

  def show_answer
    date&.strftime("%d/%m/%Y") || ""
  end
end
