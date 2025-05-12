require "rails_helper"

describe AwsSesFormSubmissionMailer, type: :mailer do
  let(:mail) { described_class.submission_email(answer_content_html:, answer_content_plain_text:, submission_email_address:, mailer_options:, files:, csv_filename:) }
  let(:title) { "Form 1" }
  let(:answer_content_html) { "My question: My answer" }
  let(:answer_content_plain_text) { "My question: My answer" }
  let(:is_preview) { false }
  let(:submission_email_address) { "testing@gov.uk" }
  let(:files) { {} }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:payment_url) { nil }
  let(:csv_filename) { nil }
  let(:submission_timestamp) { Time.utc(2022, 12, 14, 13, 0o0, 0o0) }
  let(:mailer_options) do
    FormSubmissionService::MailerOptions.new(title:,
                                             is_preview:,
                                             timestamp: submission_timestamp,
                                             submission_reference:,
                                             payment_url:)
  end

  context "when form filler submits a completed form" do
    context "when form is not in preview" do
      it "sends an email to the form's submission email address" do
        expect(mail.to).to eq([submission_email_address])
      end

      it "sets the subject" do
        expect(mail.subject).to eq("Form submission: #{title} - reference: #{submission_reference}")
      end

      describe "the html part" do
        let(:part) { mail.html_part }

        it "has a link to GOV.UK" do
          expect(part.body).to have_link("GOV.UK", href: "https://www.gov.uk")
        end

        it "includes the answers" do
          expect(part.body).to match(answer_content_html)
        end

        it "includes the form title text" do
          expect(part.body).to have_css("p", text: I18n.t("mailer.submission.title", title:))
        end

        it "includes text about the submission time" do
          expect(part.body).to have_css("p", text: I18n.t("mailer.submission.time", time: submission_timestamp.strftime("%l:%M%P").strip, date: submission_timestamp.strftime("%-d %B %Y")))
        end

        it "includes the submission reference" do
          expect(part.body).to have_css("p", text: I18n.t("mailer.submission.reference", submission_reference:))
        end

        it "includes text about checking the answers" do
          expect(part.body).to have_css("p", text: I18n.t("mailer.submission.check_before_using"))
        end

        it "includes the warning about not replying" do
          expect(part.body).to have_css("h2", text: I18n.t("mailer.submission.cannot_reply.heading"))
          expect(part.body).to include(I18n.t("mailer.submission.cannot_reply.contact_form_filler_html"))
          expect(part.body).to include(I18n.t("mailer.submission.cannot_reply.contact_forms_team_html"))
        end

        describe "submission date/time" do
          context "with a time in BST" do
            let(:submission_timestamp) { Time.utc(2022, 9, 14, 8, 0o0, 0o0).in_time_zone(submission_timezone) }

            it "includes the date and time the user submitted the form" do
              expect(part.body).to match("This form was submitted at 9:00am on 14 September 2022")
            end
          end

          context "with a time in GMT" do
            let(:submission_timestamp) { Time.utc(2022, 12, 14, 13, 0o0, 0o0).in_time_zone(submission_timezone) }

            it "includes the date and time the user submitted the form" do
              expect(part.body).to match("This form was submitted at 1:00pm on 14 December 2022")
            end
          end
        end
      end

      describe "the plaintext part" do
        let(:part) { mail.text_part }

        it "includes the answers" do
          expect(part.body).to match(answer_content_plain_text)
        end

        it "includes the form title text" do
          expect(part.body).to have_text(I18n.t("mailer.submission.title", title:))
        end

        it "includes text about the submission time" do
          expect(part.body).to have_text(I18n.t("mailer.submission.time", time: submission_timestamp.strftime("%l:%M%P").strip, date: submission_timestamp.strftime("%-d %B %Y")))
        end

        it "includes the submission reference" do
          expect(part.body).to have_text(I18n.t("mailer.submission.reference", submission_reference:))
        end

        it "includes text about checking the answers" do
          expect(part.body).to have_text(I18n.t("mailer.submission.check_before_using"))
        end

        it "includes the warning about not replying" do
          expect(part.body).to have_text(I18n.t("mailer.submission.cannot_reply.heading"))
          expect(part.body).to include(I18n.t("mailer.submission.cannot_reply.contact_form_filler_plain"))
          expect(part.body).to include(I18n.t("mailer.submission.cannot_reply.contact_forms_team_plain"))
        end

        describe "submission date/time" do
          context "with a time in BST" do
            let(:submission_timestamp) { Time.utc(2022, 9, 14, 8, 0o0, 0o0).in_time_zone(submission_timezone) }

            it "includes the date and time the user submitted the form" do
              expect(part.body).to match("This form was submitted at 9:00am on 14 September 2022")
            end
          end

          context "with a time in GMT" do
            let(:submission_timestamp) { Time.utc(2022, 12, 14, 13, 0o0, 0o0).in_time_zone(submission_timezone) }

            it "includes the date and time the user submitted the form" do
              expect(part.body).to match("This form was submitted at 1:00pm on 14 December 2022")
            end
          end
        end
      end
    end

    context "when form is in preview" do
      let(:is_preview) { true }

      it "sets the subject" do
        expect(mail.subject).to eq("TEST FORM SUBMISSION: #{title} - reference: #{submission_reference}")
      end

      describe "the html part" do
        let(:part) { mail.html_part }

        it "includes the form title text" do
          expect(part.body).to have_css("p", text: I18n.t("mailer.submission.title_preview", title:))
        end
      end

      describe "the plaintext part" do
        let(:part) { mail.text_part }

        it "includes the form title text" do
          expect(part.body).to have_text(I18n.t("mailer.submission.title_preview", title:))
        end
      end
    end

    context "when the form has a payment link" do
      let(:payment_url) { "payment_url" }

      describe "the html part" do
        let(:part) { mail.html_part }

        it "includes text about the payment" do
          expect(part.body).to have_css("p", text: I18n.t("mailer.submission.payment"))
        end
      end

      describe "the plaintext part" do
        let(:part) { mail.text_part }

        it "includes text about the payment" do
          expect(part.body).to have_text(I18n.t("mailer.submission.payment"))
        end
      end
    end

    context "when the form does not have a payment link" do
      describe "the html part" do
        let(:part) { mail.html_part }

        it "does not include text about the payment" do
          expect(part.body).not_to have_css("p", text: I18n.t("mailer.submission.payment"))
        end
      end

      describe "the plaintext part" do
        let(:part) { mail.text_part }

        it "does not include text about the payment" do
          expect(part.body).not_to have_text(I18n.t("mailer.submission.payment"))
        end
      end
    end

    context "when the csv file of answers is attached" do
      let(:csv_filename) { "my_answers.csv" }

      describe "the html part" do
        let(:part) { mail.html_part }

        it "includes a heading about an answers CSV file" do
          expect(part.body).to have_css("h2", text: I18n.t("mailer.submission.csv_file"))
        end

        it "includes the CSV filename" do
          expect(part.body).to have_css("p", text: I18n.t("mailer.submission.file_attached", filename: csv_filename))
        end
      end

      describe "the plaintext part" do
        let(:part) { mail.text_part }

        it "includes text about an answers CSV file" do
          expect(part.body).to have_text(I18n.t("mailer.submission.csv_file"))
        end

        it "includes the CSV filename" do
          expect(part.body).to have_text(I18n.t("mailer.submission.file_attached", filename: csv_filename))
        end
      end
    end

    context "when the csv file of answers is not attached" do
      describe "the html part" do
        let(:part) { mail.html_part }

        it "does not include a heading about an answers CSV file" do
          expect(part.body).not_to have_css("h2", text: I18n.t("mailer.submission.csv_file"))
        end

        it "does not include the CSV filename" do
          expect(part.body).not_to have_css("p", text: I18n.t("mailer.submission.file_attached", filename: csv_filename))
        end
      end

      describe "the plaintext part" do
        let(:part) { mail.text_part }

        it "does not include text about an answers CSV file" do
          expect(part.body).not_to have_text(I18n.t("mailer.submission.csv_file"))
        end

        it "does not include the CSV filename" do
          expect(part.body).not_to have_text(I18n.t("mailer.submission.file_attached", filename: csv_filename))
        end
      end
    end
  end

  context "when files to attach are included in the arguments" do
    let(:csv_file_name) { "first-file.csv" }
    let(:png_file_name) { "second-file.png" }
    let(:files) do
      {
        csv_file_name => Faker::Lorem.sentence,
        png_file_name => Faker::Lorem.sentence,
      }
    end

    it "has 2 attachments" do
      expect(mail.attachments.size).to eq(2)
    end

    it "has the files attached with expected filenames" do
      expect(mail.attachments[0].filename).to eq(csv_file_name)
      expect(mail.attachments[1].filename).to eq(png_file_name)
    end

    it "has the files attached with expected content" do
      expect(mail.attachments[0].body).to eq(files[csv_file_name])
      expect(mail.attachments[1].body).to eq(files[png_file_name])
    end
  end

private

  def submission_timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end
end
