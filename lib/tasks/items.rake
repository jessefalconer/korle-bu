# frozen_string_literal: true

# Moving typed-in serial numbers into items.serial_number (see SerialNumberExtraction).
#
#   bin/rails items:extract_serial_numbers            # dry run: writes a preview, changes nothing
#   bin/rails items:extract_serial_numbers APPLY=1    # makes the automatic changes, after a backup
#   bin/rails items:restore_serial_numbers BACKUP=tmp/serial_number_backup-....csv
#
# PREVIEW=path and BACKUP=path override where the files go (default: tmp/).
namespace :items do
  desc "Move serial numbers typed into item brands and names into the S/N field (APPLY=1 to change data)"
  task extract_serial_numbers: :environment do
    changes = SerialNumberExtraction.plan
    preview = ENV.fetch("PREVIEW", Rails.root.join("tmp/serial_number_preview.csv").to_s)
    SerialNumberExtraction.write_preview(changes, preview)

    counts = SerialNumberExtraction.summary(changes)
    puts "Items mentioning a serial: #{changes.size}"
    puts "  automatic:        #{counts.fetch(:auto, 0)}"
    puts "  need a person:    #{counts.fetch(:review, 0)}"
    puts "  notes only, left: #{counts.fetch(:skip, 0)}"
    puts "Preview (review rows first): #{preview}"

    unless ENV["APPLY"] == "1"
      puts "\nDry run: nothing changed. Re-run with APPLY=1 to make the automatic changes."
      next
    end

    backup = ENV.fetch("BACKUP", Rails.root.join("tmp/serial_number_backup-#{Time.current.strftime("%Y%m%d-%H%M%S")}.csv").to_s)
    applied, skipped = SerialNumberExtraction.apply!(changes, backup)
    puts "\nApplied #{applied} changes (#{skipped} skipped: edited since the plan was made)."
    puts "Backup of the old values: #{backup}"
    puts "To undo: bin/rails items:restore_serial_numbers BACKUP=#{backup}"
  end

  desc "Undo items:extract_serial_numbers from its backup (BACKUP=path)"
  task restore_serial_numbers: :environment do
    backup = ENV.fetch("BACKUP") { abort "Give the backup to restore: BACKUP=tmp/serial_number_backup-....csv" }
    abort "No such file: #{backup}" unless File.exist?(backup)

    puts "Restored #{SerialNumberExtraction.restore!(backup)} items from #{backup}"
  end
end
