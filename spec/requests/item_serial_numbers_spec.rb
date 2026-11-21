# frozen_string_literal: true

require "rails_helper"

# The S/N field on the item form, and saving it from every place items are made.
describe "Item serial numbers", type: :request do
  let(:admin) { create :user, status: "Active", role: "Admin" }

  before { sign_in admin }

  it "puts an S/N field between Brand/Model and Unit Weight" do
    get new_item_path

    labels = response.parsed_body.css(".item-fields label").map { |label| label.text.strip }
    brand = labels.index("Brand/Model")
    expect(labels[brand + 1]).to eq("S/N")
    expect(labels[brand + 2]).to eq("Unit Weight (kg)")
  end

  it "saves it from the item form" do
    post items_path, params: { item: { object: "Hospital Bed", brand: "Stryker FL28C", serial_number: "R20722" } }

    item = Item.last
    expect(item.serial_number).to eq("R20722")
    expect(item.generated_name).to eq("Stryker FL28C Hospital Bed S/N R20722")

    get item_path(item)
    expect(response.parsed_body.at_css("h5.serial-number").text).to eq("R20722")
  end

  it "saves it when an item is created while packing a box" do
    box = create :box, pallet: nil, container: nil
    post box_add_with_item_path(box), params: {
      item: { object: "Baby Warmer", serial_number: "ARCZ-0058" },
      packed_item: { quantity: 1 }
    }

    expect(Item.find_by(serial_number: "ARCZ-0058").generated_name).to eq("Baby Warmer S/N ARCZ-0058")
    expect(box.box_items.sole.item.serial_number).to eq("ARCZ-0058")
  end
end
