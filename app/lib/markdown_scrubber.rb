class MarkdownScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w[a h2 h3 ol ul li p]
    self.attributes = %w[href class rel target title]
  end
end
