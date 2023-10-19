class EmailConfirmationForm
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :send_confirmation, :confirmation_email_address, :notify_reference
end
