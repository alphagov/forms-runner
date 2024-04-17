class LimitedHtmlScrubber < Rails::Html::PermitScrubber
  def initialize(allow_headings: false)
    super()

    self.tags = ["a", "ol", "ul", "li", "p", "br", *(%w[h2 h3] if allow_headings)]

    self.attributes = %w[href class rel target title]
  end
end
