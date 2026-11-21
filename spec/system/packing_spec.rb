# frozen_string_literal: true

require "rails_helper"

# src/manage_item_search.js: recent items, weight from unit weight, and the
# search → Enter → Enter → quantity → Enter keyboard flow on packing pages.
describe "Packing items into a box", type: :system do
  let(:volunteer) { create :user, status: "Active", role: "Volunteer" }
  let(:box) { create :box, pallet: nil, container: nil, status: Box::IN_PROGRESS }
  let!(:backboard) { create :item, object: "Backboard", unit_weight: 6.5 }

  before { log_in_as volunteer }

  def focused_id
    page.evaluate_script("document.activeElement.id")
  end

  it "packs an item using only the keyboard, filling in weight from the unit weight" do
    visit_page box_box_items_path(box)
    expect(focused_id).to eq("search-params")

    search = find("#search-params")
    search.send_keys("backboard", :enter)
    expect(page).to have_css("#search-results .results-item-name", text: "Backboard")

    search.send_keys(:enter) # opens the first result, quantity selected
    expect(focused_id).to eq("quantity-#{backboard.id}")
    expect(find("#weight-#{backboard.id}").value).to eq("6.5")

    page.active_element.send_keys("3")
    expect(find("#weight-#{backboard.id}").value).to eq("19.5")

    page.active_element.send_keys(:enter) # adds it
    expect(page).to have_css("#search-params:focus")
    packed = box.box_items.sole
    expect([packed.item, packed.quantity, packed.weight]).to eq([backboard, 3, 19.5])
  end

  it "stops filling in weight once someone types their own" do
    visit_page box_box_items_path(box)
    find("#search-params").send_keys("backboard", :enter)
    find("#search-results .results-item-name", text: "Backboard").click

    find("#weight-#{backboard.id}").fill_in(with: "20")
    find("#quantity-#{backboard.id}").fill_in(with: "5")

    expect(find("#weight-#{backboard.id}").value).to eq("20")
  end

  it "shows recently packed items until a search is typed, and again after Escape" do
    create :packed_item, item: backboard, user: volunteer, box: box, pallet: nil, container: nil, shipment: nil
    visit_page box_box_items_path(box)
    expect(page).to have_css("#recent-items .results-item-name", text: "Backboard")

    find("#search-params").send_keys("back")
    expect(page).to have_no_css("#recent-items", visible: :visible)

    find("#search-params").send_keys(:escape)
    expect(find("#search-params").value).to eq("")
    expect(page).to have_css("#recent-items", visible: :visible)
  end

  it "moves between results with the arrow keys" do
    create :item, object: "Backboard Strap"
    visit_page box_box_items_path(box)
    find("#search-params").send_keys("backboard", :enter)
    expect(page).to have_css("#search-results .results-item-name", count: 2)

    find("#search-params").send_keys(:down)
    first, second = all("#search-results .results-item-name").to_a
    expect(first).to match_selector(":focus")
    page.active_element.send_keys(:down)
    expect(second).to match_selector(":focus")
    page.active_element.send_keys(:up, :up)
    expect(focused_id).to eq("search-params")
  end
end
