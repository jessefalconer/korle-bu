# frozen_string_literal: true

# rubocop:disable Naming/HeredocDelimiterNaming
task kpsql: :environment do
  db_name = "#{File.basename(Rails.root)}_#{Rails.env}"
  sh = <<~EOF
    ps xa \
      | grep postgres: \
      | grep #{db_name} \
      | grep -v grep \
      | awk '{print $1}' \
      | xargs kill
  EOF
  puts `#{sh}`
end
# rubocop:enable Naming/HeredocDelimiterNaming
