# frozen_string_literal: true

require "rails_helper"

describe UnpackingEventsExport do
  let(:hospital) { create :hospital, name: "Ridge Hospital" }
  let(:other_hospital) { create :hospital, name: "Tema General" }
  let(:volunteer) { create :user, first_name: "Efua", last_name: "Owusu" }
  let(:item) { create :item, object: "Syringe" }
  let(:box) { create :box, pallet: nil, container: nil }
  let(:packed_item) { create :packed_item, item: item, box: box, pallet: nil, container: nil, quantity: 50 }

  def event_at(time, quantity:, hospital: self.hospital)
    create(:unpacking_event, packed_item: packed_item, hospital: hospital, user: volunteer, quantity: quantity).tap do |e|
      e.update_columns(timestamp: time, created_at: time)
    end
  end

  def rows(start_date: "2026-01-01", end_date: "2026-12-31", hospital_id: nil, sorting: "asc")
    CSV.parse(UnpackingEventsExport.new(start_date, end_date, hospital_id, sorting).to_csv)
  end

  before do
    event_at(Time.zone.parse("2026-02-01 10:00"), quantity: 1)
    event_at(Time.zone.parse("2026-03-01 10:00"), quantity: 2, hospital: other_hospital)
    event_at(Time.zone.parse("2025-06-01 10:00"), quantity: 3)
  end

  it "writes a header and one row per event in range" do
    header, *body = rows

    expect(header).to eq(["Item", "Item ID", "Quantity", "Origin", "Destination", "User", "Date"])
    expect(body).to eq([
                         ["Syringe", item.id.to_s, "1", box.name, "Ridge Hospital", "Efua Owusu", "2026-02-01"],
                         ["Syringe", item.id.to_s, "2", box.name, "Tema General", "Efua Owusu", "2026-03-01"]
                       ])
  end

  it "filters by hospital" do
    _, *body = rows(hospital_id: hospital.id)
    expect(body.pluck(4)).to eq(["Ridge Hospital"])
  end

  it "sorts descending when asked" do
    _, *body = rows(sorting: "desc")
    expect(body.pluck(6)).to eq(%w[2026-03-01 2026-02-01])
  end

  it "defaults the start date to the earliest event" do
    _, *body = rows(start_date: nil)
    expect(body.pluck(2)).to contain_exactly("1", "2", "3")
  end
end
