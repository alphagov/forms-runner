module Question
  class Date < Question::QuestionBase
    attribute :date_day
    attribute :date_month
    attribute :date_year
    attribute :date

    validate :date_valid

    def assign_attributes(new_attributes)
      translated_attrs = new_attributes.transform_keys { |key| date_field_to_attribute(key) }
      super(translated_attrs)
    end

    def date
      valid_or_invalid_date(date_year, date_month, date_day)
    end

    def show_answer
      if date.is_a?(::Date)
        date.strftime("%d/%m/%Y")
      else
        ""
      end
    end

  private

    def date_valid
      return errors.add(:date, :blank) if blank?
      return errors.add(:date, :blank_date_fields, fields: blank_fields.to_sentence) if present? && blank_fields.any?
      return errors.add(:date, :invalid_date) if invalid?
    end

    def date_field_to_attribute(key)
      case key
      when "date(3i)" then "date_day"
      when "date(2i)" then "date_month"
      when "date(1i)" then "date_year"
      else key
      end
    end

    def invalid?
      !date.is_a?(::Date)
    end

    def blank?
      return false if date.is_a?(::Date)

      date_fields = %i[day month year]
      date.to_h.slice(*date_fields).all? { |_, v| v.blank? }
    end

    def blank_fields
      return [] if date.is_a?(::Date)

      date.to_h.select { |_, v| v.blank? }.keys
    end

    def valid_or_invalid_date(year, month, day)
      raise ArgumentError if year.blank?

      # Use Integer here rather than to_i otherwise an string in year can be
      # transformed to zero, which is a valid year for Date
      date_args = [year, month, day].map do |i|
        integer = Integer(i, 10)
        raise RangeError unless integer.positive?

        integer
      end

      if date_args[1].zero?
        date_args[1] = ::Date.parse(month).month
      end

      ::Date.new(*date_args)
    rescue ArgumentError, RangeError
      Struct.new(:day, :month, :year).new(day, month, year)
    end
  end
end
