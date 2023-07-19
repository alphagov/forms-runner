module Question
  module DateComponent
    class View < Question::Base
    private

      def date_of_birth?
        question.answer_settings != {} && question.answer_settings&.input_type == "date_of_birth"
      end
    end
  end
end
