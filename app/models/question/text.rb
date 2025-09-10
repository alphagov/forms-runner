module Question
  class Text < QuestionBase
    attribute :text
    validates :text, presence: true, unless: :is_optional?
    validates :text, length: { maximum: 499, message: I18n.t("activemodel.errors.models.question/text.attributes.text.single_line_too_long") }, if: :is_single_line?
    validates :text, length: { maximum: 4999, message: I18n.t("activemodel.errors.models.question/text.attributes.text.long_text_too_long") }, unless: :is_single_line?

    before_validation :strip_carriage_returns!, unless: :is_single_line?

    def is_single_line?
      answer_settings.input_type == "single_line"
    end

    def has_long_answer?
      !is_single_line?
    end

  private

    def strip_carriage_returns!
      text.gsub!(/\r\n?/, "\n") if text.present?
    end
  end
end
