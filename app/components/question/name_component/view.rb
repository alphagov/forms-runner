module Question
  module NameComponent
    class View < Question::Base
      attr_accessor :name_html

      def before_render
        @name_html = build_fields
      end

    private

      def needs_title?
        question.answer_settings.present? && question.answer_settings.title_needed == "true"
      end

      def is_full_name?
        question.answer_settings.present? && question.answer_settings.input_type == "full_name"
      end

      def include_middle_name?
        question.answer_settings.present? && question.answer_settings.input_type == "first_middle_and_last_name"
      end

      def build_fields
        form_fields = show_full_name_and_no_title ? fields_for_full_name_and_no_title : fields_for_name_with_or_without_title

        safe_join([form_fields].compact_blank)
      end

      def show_full_name_and_no_title
        is_full_name? && !needs_title?
      end

      def fields_for_full_name_and_no_title
        form_builder.govuk_text_field :full_name,
                                      label: { tag: "h1", size: "l", text: question_text_with_extra_suffix },
                                      hint: { text: question.hint_text },
                                      autocomplete: "name"
      end

      def fields_for_name_with_or_without_title
        form_builder.govuk_fieldset legend: { text: question_text_with_extra_suffix, tag: "h1", size: "l" }, described_by: hint_id do
          form_fields = if is_full_name?
                          [
                            (form_builder.govuk_text_field :full_name, label: { text: t("question/name.label.full_name") }, autocomplete: "name"),
                          ]
                        else
                          [
                            (form_builder.govuk_text_field :first_name, label: { text: t("question/name.label.first_name") }, width: "one-half", autocomplete: "given-name"),
                            (form_builder.govuk_text_field(:middle_names, label: { text: t("question/name.label.middle_names") }, width: "two-thirds", autocomplete: "additional-name") if include_middle_name?),
                            (form_builder.govuk_text_field :last_name, label: { text: t("question/name.label.last_name") }, width: "one-half", autocomplete: "family-name"),
                          ]
                        end

          safe_join([
            hint_text,
            title_field,
            form_fields,
          ])
        end
      end

      def title_field
        return nil unless needs_title?

        form_builder.govuk_text_field :title, label: { text: t("question/name.label.title") }, width: "one-quarter", autocomplete: "honorific-prefix"
      end
    end
  end
end
