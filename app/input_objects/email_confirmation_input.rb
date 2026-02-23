class EmailConfirmationInput
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  attr_accessor :send_confirmation, :confirmation_email_address

  before_validation :strip_email_whitespace

  validates :send_confirmation, presence: true
  validates :send_confirmation, inclusion: { in: %w[send_email skip_confirmation] }
  validates :confirmation_email_address, presence: true, if: :validate_email?
  validates :confirmation_email_address, email_address: { message: :invalid_email }, allow_blank: true, if: :validate_email?

  def validate_email?
    send_confirmation == "send_email"
  end

  def strip_email_whitespace
    if confirmation_email_address.present?
      self.confirmation_email_address = NotificationsUtils::Formatters.strip_and_remove_obscure_whitespace(confirmation_email_address)
    end
  end
end
