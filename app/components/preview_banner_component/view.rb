module PreviewBannerComponent
  class View < ViewComponent::Base
    def initialize(mode:)
      @mode = mode || Mode.new

      super
    end

    def render?
      @mode.preview?
    end
  end
end
