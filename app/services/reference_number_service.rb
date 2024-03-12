class ReferenceNumberService
  ALPHABETICAL_CHARACTER_SET = %w[A B C D E F G H J K L M N P R S T U V W X Y].freeze
  NUMERIC_CHARACTER_SET = %w[2 3 4 5 6 7 8 9].freeze
  ALPHANUMERIC_CHARACTER_SET = ALPHABETICAL_CHARACTER_SET + NUMERIC_CHARACTER_SET
  REFERENCE_LENGTH = 8

  def self.generate
    (0...REFERENCE_LENGTH)
      .map { |i|
        if i % 3 == 2
          NUMERIC_CHARACTER_SET.sample
        else
          ALPHANUMERIC_CHARACTER_SET.sample
        end
      }.join
  end
end
