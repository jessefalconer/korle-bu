# frozen_string_literal: true

require "rails_helper"

describe HospitalExport do
  let(:hospital) { create :hospital }
  let(:other_hospital) { create :hospital }
  let(:volunteer) { create :user, first_name: "Kwame", last_name: "Asante" }
  let(:category) { create :category, name: "Medical" }
  let(:item) { create :item, object: "Gauze", category: category }
  let(:packed_item) do
    create :packed_item, item: item, box: nil, pallet: nil, container: nil,
                         status: PackedItem::WAREHOUSED, quantity: 20
  end

  def event_on(date, quantity:, hospital: self.hospital)
    create(:unpacking_event, packed_item: packed_item, hospital: hospital, user: volunteer, quantity: quantity).tap do |e|
      e.update_columns(created_at: date.to_datetime.middle_of_day)
    end
  end

  def rows(options = {})
    CSV.parse(HospitalExport.new(hospital.id, options).to_csv)
  end

  it "exports events in the date range in chronological order" do
    event_on(Date.new(2026, 3, 2), quantity: 4)
    event_on(Date.new(2026, 3, 1), quantity: 3)
    event_on(Date.new(2026, 4, 1), quantity: 9)

    header, *body = rows("start_date" => "2026-03-01", "end_date" => "2026-03-31")

    expect(header).to eq(%w[Item Category Quantity User Date])
    expect(body).to eq([
                         ["Gauze", "Medical", "3", "Kwame Asante", "2026-03-01"],
                         ["Gauze", "Medical", "4", "Kwame Asante", "2026-03-02"]
                       ])
  end

  it "includes events on the start and end days" do
    event_on(Date.new(2026, 3, 1), quantity: 1)
    event_on(Date.new(2026, 3, 31), quantity: 2)

    _, *body = rows("start_date" => "2026-03-01", "end_date" => "2026-03-31")
    expect(body.pluck(2)).to eq(%w[1 2])
  end

  it "ignores other hospitals' events" do
    event_on(Date.new(2026, 3, 1), quantity: 1, hospital: other_hospital)

    _, *body = rows("start_date" => "2026-03-01", "end_date" => "2026-03-31")
    expect(body).to be_empty
  end

  it "defaults to today's events" do
    event_on(Time.zone.today, quantity: 6)
    event_on(Time.zone.today - 1, quantity: 7)

    _, *body = rows
    expect(body.pluck(2)).to eq(%w[6])
  end
end
