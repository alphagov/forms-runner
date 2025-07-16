class EmailConfirmationInput
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :send_confirmation, :confirmation_email_address

  validates :send_confirmation, presence: true
  validates :send_confirmation, inclusion: { in: %w[send_email skip_confirmation] }
  validates :confirmation_email_address, presence: true, if: :validate_email?
  validates :confirmation_email_address, email_address: { message: :invalid_email }, allow_blank: true, if: :validate_email?

  def validate_email?
    send_confirmation == "send_email"
  end
end
