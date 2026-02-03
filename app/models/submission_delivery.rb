class SubmissionDelivery < ApplicationRecord
  belongs_to :submission
  belongs_to :delivery

  after_destroy :destroy_delivery

private

  def destroy_delivery
    if delivery.submission_deliveries.reload.none? && !delivery.destroyed?
      delivery.destroy!
    end
  end
end
