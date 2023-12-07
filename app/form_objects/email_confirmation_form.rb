class EmailConfirmationForm
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :send_confirmation, :confirmation_email_address, :confirmation_email_reference, :notify_reference

  validates :send_confirmation, presence: true
  validates :send_confirmation, inclusion: { in: %w[send_email skip_confirmation] }
  validates :confirmation_email_address, presence: true, if: :validate_email?
  validates :confirmation_email_address, format: { with: URI::MailTo::EMAIL_REGEXP, message: :invalid_email }, allow_blank: true, if: :validate_email?

  def initialize(...)
    super(...)
    generate_submission_references! unless @confirmation_email_reference || @notify_reference
  end

  def validate_email?
    send_confirmation == "send_email"
  end

private

  def generate_submission_references!
    reference = SecureRandom.uuid
    self.attributes = {
      confirmation_email_reference: "#{reference}-confirmation-email",
      notify_reference: "#{reference}-submission-email",
    }
  end
end
