class Delivery < ApplicationRecord
  has_many :submission_deliveries, dependent: :destroy
  has_many :submissions, through: :submission_deliveries

  scope :pending, -> { where(delivered_at: nil, failed_at: nil) }
  scope :delivered, -> { where.not(delivered_at: nil).where("failed_at IS NULL OR delivered_at > failed_at") }
  scope :failed, -> { where.not(failed_at: nil).where("delivered_at IS NULL OR delivered_at <= failed_at") }

  def status
    return :pending if delivered_at.nil? && failed_at.nil?
    return :delivered if delivered_at.present? && failed_at.nil?
    return :failed if failed_at.present? && delivered_at.nil?

    delivered_at > failed_at ? :delivered : :failed
  end

  %i[pending delivered failed].each do |status|
    define_method("#{status}?") do
      self.status == status
    end
  end
end
