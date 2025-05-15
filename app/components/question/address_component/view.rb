module Question
  module AddressComponent
    class View < Question::Base
      attr_accessor :address_html

      def before_render
        @address_html = build_fields
      end

    private

      def is_international_address?
        question.answer_settings.present? && question.answer_settings&.input_type&.international_address == "true"
      end

      def build_fields
        form_builder.govuk_fieldset legend: { text: question_text_with_extra_suffix, **question_text_size_and_tag }, described_by: hint_id do
          form_fields = is_international_address? ? fields_for_international_address : fields_for_uk_address
          safe_join([hint_text, form_fields].compact_blank)
        end
      end

      def fields_for_international_address
        safe_join([
          form_builder.govuk_text_area(:street_address, label: { text: I18n.t("question/address.label.international_address.street_address") }, rows: 5, autocomplete: "street-address"),
          form_builder.govuk_text_field(:country, label: { text: I18n.t("question/address.label.international_address.country") }, width: 20, autocomplete: "country-name"),
        ])
      end

      def fields_for_uk_address
        safe_join([
          form_builder.govuk_text_field(:address1, label: { text: I18n.t("question/address.label.uk_address.line_1") }, autocomplete: "address-line1"),
          form_builder.govuk_text_field(:address2, label: { text: I18n.t("question/address.label.uk_address.line_2") }, autocomplete: "address-line2"),
          form_builder.govuk_text_field(:town_or_city, label: { text: I18n.t("question/address.label.uk_address.town_or_city") }, width: "two-thirds", autocomplete: "address-level2"),
          form_builder.govuk_text_field(:county, label: { text: I18n.t("question/address.label.uk_address.county") }, width: "two-thirds"),
          form_builder.govuk_text_field(:postcode, label: { text: I18n.t("question/address.label.uk_address.postcode") }, width: 10, autocomplete: "postal-code"),
        ])
      end
    end
  end
end
