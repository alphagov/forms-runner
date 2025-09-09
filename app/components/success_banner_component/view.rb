module SuccessBannerComponent
  class View < ApplicationComponent
    def initialize(success:)
      @success = success
      super()
    end

    def render?
      @success.present?
    end
  end
end
