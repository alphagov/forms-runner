module SubmissionFilenameGenerator
  MAX_LENGTH = 100
  PREFIX = "govuk_forms_".freeze
  CSV_EXTENSION = ".csv".freeze
  JSON_EXTENSION = ".json".freeze

  def self.csv_filename(form_name:, submission_reference:)
    filename(form_name:, submission_reference:, extension: CSV_EXTENSION)
  end

  def self.json_filename(form_name:, submission_reference:)
    filename(form_name:, submission_reference:, extension: JSON_EXTENSION)
  end

  def self.filename(form_name:, submission_reference:, extension:)
    reference_part = "_#{submission_reference}"

    name_part_max_length = MAX_LENGTH - extension.length - PREFIX.length - reference_part.length

    name_part = form_name
      .parameterize(separator: "_")
      .truncate(name_part_max_length, separator: "_", omission: "")
    "#{PREFIX}#{name_part}#{reference_part}#{extension}"
  end

  def self.batch_csv_filename(form_name:, date:, mode:, form_version:)
    date_part = date.strftime("_%Y-%m-%d")
    mode_prefix = mode.preview? ? "test_" : ""
    version_part = form_version.presence ? "_#{form_version}" : ""

    name_part_max_length = MAX_LENGTH - CSV_EXTENSION.length - mode_prefix.length - PREFIX.length - date_part.length - version_part.length

    name_part = form_name
      .parameterize(separator: "_")
      .truncate(name_part_max_length, separator: "_", omission: "")

    "#{mode_prefix}#{PREFIX}#{name_part}#{date_part}#{version_part}#{CSV_EXTENSION}"
  end
end
