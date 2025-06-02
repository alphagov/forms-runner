RSpec.shared_context "with locale set to :en" do
  around do |example|
    I18n.with_locale(:en) do
      example.run
    end
  end
end

RSpec.shared_context "with locale set to :cy" do
  around do |example|
    I18n.with_locale(:cy) do
      example.run
    end
  end
end
