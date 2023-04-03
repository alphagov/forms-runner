module PreviewComponent
  class View < ViewComponent::Base
    def initialize(mode:)
      @mode = mode || Mode.new
    end

    def call
      govuk_phase_banner(tag: {
        text: t("mode.phase_banner_tag_#{@mode}"),
        colour: phase_banner_colour
      },
      text: t("mode.phase_banner_text_#{@mode}"))
    end

    def render?
      @mode.preview?
    end

    private

    def phase_banner_colour
      if @mode.preview_draft?
        'purple'
      else
        'blue'
      end
    end
  end
end
