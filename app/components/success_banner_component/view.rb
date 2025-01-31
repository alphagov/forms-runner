module SuccessBannerComponent
  class View < ViewComponent::Base
    def initialize(success:)
      @success = success
      super
    end

    def render?
      @success.present?
    end
  end
end
