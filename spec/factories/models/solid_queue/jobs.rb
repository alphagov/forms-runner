FactoryBot.define do
  factory :solid_queue_job, class: SolidQueue::Job do
    queue_name { "default" }
    class_name { SendSubmissionJob.name }
    active_job_id { Faker::Alphanumeric.alphanumeric }
    arguments { {} }
  end
end
