class EmailConfirmationForm
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :send_confirmation, :confirmation_email_address, :confirmation_email_reference, :notify_reference

  validates :send_confirmation, presence: true, if: :validate_presence?
  validates :send_confirmation, inclusion: { in: %w[send_email skip_confirmation] }, if: :validate_presence?
  validates :confirmation_email_address, presence: true, if: :validate_email?
  validates :confirmation_email_address, format: { with: URI::MailTo::EMAIL_REGEXP, message: :invalid_email }, allow_blank: true, if: :validate_email?

  def validate_email?
    FeatureService.enabled?(:email_confirmations_enabled) && send_confirmation == "send_email"
  end

  def validate_presence?
    FeatureService.enabled?(:email_confirmations_enabled)
  end
end
