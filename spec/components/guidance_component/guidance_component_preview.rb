class GuidanceComponent::GuidanceComponentPreview < ViewComponent::Preview
  def default
    question = OpenStruct.new(
      page_heading: nil,
      guidance_markdown: nil,
    )

    render(GuidanceComponent::View.new(question))
  end

  def with_paragraph_content
    question = OpenStruct.new(
      page_heading: "Interview needs",
      guidance_markdown: "Providers do not usually have much flexibility when setting a date and time for interview unless you need adjustments due to a [health condition or disability](#).\n\nHowever, if you need flexibility for other reasons you can tell us about it here.\n\nFor example, you have commitments like caring responsibilites or employment.\n\nContact your provider if you’re concerned about the interview process.",
    )

    render(GuidanceComponent::View.new(question))
  end

  def with_bulleted_list
    question = OpenStruct.new(
      page_heading: "10 figure grid reference of the proposed location of the building",
      guidance_markdown: "## How to find your 10 figure grid reference\n\nIn order to find the relevant grid reference you should do the following: \n\n* Go to the [Grid Reference Finder](https://gridreferencefinder.com/) website\n* Search for your location by postcode or using the other search fields\n* Click on the location",
    )

    render(GuidanceComponent::View.new(question))
  end

  def with_numbered_list
    question = OpenStruct.new(
      page_heading: "National Grid field number for the proposed location of the building",
      guidance_markdown: "## How to find National Grid field numbers for your land or building\n\nUse the [multi-agency geographic information for the countryside (MAGIC) map](https://magic.defra.gov.uk/).\n\n### Instructions:\n\n1. Select ‘Get Started’.\n2. Search for a county, place or postcode.\n3. Using the map, locate the land or building. Use the +/-icons to zoom in and out.\n4. Select the ‘Where am I’ function on the toolbar and then click on the land or building.\n5. A pop-up box will appear showing the land details for this location. This includes the National Grid field number.",
    )

    render(GuidanceComponent::View.new(question))
  end
end
