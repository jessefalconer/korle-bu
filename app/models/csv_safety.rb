# frozen_string_literal: true

# Makes CSV exports safe and readable once they're opened in a spreadsheet.
module CsvSafety
  # Excel only reads a CSV as UTF-8 (so accented names come out right) when the
  # file starts with this byte-order mark. Other spreadsheet apps ignore it.
  BOM = "﻿"

  # A cell starting with one of these is run as a formula by Excel, Sheets and
  # LibreOffice. Item names and notes are typed by users, so one could be made
  # to run something when the file is opened ("CSV injection").
  FORMULA_START = /\A[=+\-@\t\r]/

  # Text that would run as a formula gets a leading apostrophe, which spreadsheets
  # show as plain text. Numbers, and the lone "-" exports use as a filler, are left alone.
  def self.cell(value)
    return value unless value.is_a?(String) && value != "-" && value.match?(FORMULA_START)

    "'#{value}"
  end

  def self.row(values)
    values.map { |value| cell(value) }
  end
end
