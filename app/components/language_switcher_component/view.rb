# frozen_string_literal: true

module LanguageSwitcherComponent
  class View < ApplicationComponent
    def initialize(languages: [])
      super()
      @languages = languages
    end

    def render?
      @languages.present? && @languages.count > 1
    end

  private

    def locale(language)
      language unless default_locale?(language)
    end

    def default_locale?(locale)
      return true if locale.nil?
      return true if locale.to_sym == I18n.default_locale

      false
    end

    def current_locale?(locale)
      return true if locale.nil?
      return true if locale.to_sym == I18n.locale

      false
    end

    def language_local_name(language)
      I18n.t("language_name", locale: language)
    end
  end
end
