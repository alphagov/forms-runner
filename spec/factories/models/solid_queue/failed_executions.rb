FactoryBot.define do
  factory :solid_queue_failed_execution, class: SolidQueue::FailedExecution do
    job { association :solid_queue_job }
  end
end
