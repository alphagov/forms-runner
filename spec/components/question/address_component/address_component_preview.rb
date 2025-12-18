class Question::AddressComponent::AddressComponentPreview < ViewComponent::Preview
  def international_address_field
    question = OpenStruct.new(street_address: "237 Bogisich Way,\nNorth Desmond\nNH 16786",
                              country: "USA",
                              answer_type: "address",
                              is_optional?: false,
                              question_text_with_optional_suffix: "What is your international address",
                              answer_settings: OpenStruct.new(input_type: OpenStruct.new(international_address: "true")))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::AddressComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end

  def international_address_field_with_hint
    question = OpenStruct.new(street_address: "237 Bogisich Way,\nNorth Desmond\nNH 16786",
                              country: "USA",
                              answer_type: "address",
                              is_optional?: false,
                              hint_text: "Must be outside UK",
                              question_text_with_optional_suffix: "What is your international address",
                              answer_settings: OpenStruct.new(input_type: OpenStruct.new(international_address: "true")))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::AddressComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end

  def uk_address_field
    question = OpenStruct.new(address1: "Flat 4",
                              address2: "Gibbons tunnel",
                              town_or_city: "Lesleystad",
                              county: "London",
                              postcode: "L8C 2EZ",
                              answer_type: "address",
                              is_optional?: false,
                              question_text_with_optional_suffix: "What is your UK address",
                              answer_settings: OpenStruct.new(input_type: OpenStruct.new(uk_address: "true", international_address: "false")))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::AddressComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end

  def uk_address_field_with_hint
    question = OpenStruct.new(address1: "Flat 4",
                              address2: "Gibbons tunnel",
                              town_or_city: "Lesleystad",
                              county: "London",
                              postcode: "L8C 2EZ",
                              answer_type: "address",
                              is_optional?: false,
                              hint_text: "Must be inside UK",
                              question_text_with_optional_suffix: "What is your UK address",
                              answer_settings: OpenStruct.new(input_type: OpenStruct.new(uk_address: "true")))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::AddressComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end

  def any_address_field
    question = OpenStruct.new(street_address: "237 Bogisich Way,\nNorth Desmond\nNH 16786",
                              country: "USA",
                              answer_type: "address",
                              is_optional?: false,
                              hint_text: "It can be either UK address or international",
                              question_text_with_optional_suffix: "What is your address",
                              answer_settings: OpenStruct.new(input_type: OpenStruct.new(uk_address: "true", international_address: "true")))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::AddressComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end

  def any_address_field_with_hint
    question = OpenStruct.new(street_address: "237 Bogisich Way,\nNorth Desmond\nNH 16786",
                              country: "USA",
                              answer_type: "address",
                              is_optional?: false,
                              hint_text: "It can be either UK address or international",
                              question_text_with_optional_suffix: "What is your address",
                              answer_settings: OpenStruct.new(input_type: OpenStruct.new(uk_address: "true", international_address: "true")))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::AddressComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end
end
