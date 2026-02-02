class SubmissionDelivery < ApplicationRecord
  belongs_to :submission
  belongs_to :delivery
end
