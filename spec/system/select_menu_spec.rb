# frozen_string_literal: true

require "rails_helper"

# src/select_menu.js: styled dropdowns drawn over the real (hidden) <select>.
describe "Styled dropdowns", type: :system do
  let(:admin) { create :user, status: "Active", role: "Admin" }

  before { log_in_as admin }

  def menu_button(select_id)
    find("##{select_id} + .select-menu .select-menu-button")
  end

  def open_list
    find(".select-menu-popup:not([hidden])")
  end

  # The real <select> is clipped to 1px, which Capybara still counts as visible
  def native(select_id)
    find("##{select_id}", visible: :all)
  end

  # Opens the filter panel (a <details>)
  def open_filters
    find(".list-filter summary").click
    expect(page).to have_css(".list-filter[open] .list-filter-form")
  end

  it "replaces each select with a button showing its current choice, keeping the select for the form" do
    visit_page new_item_path

    expect(page).to have_css(".select-menu-button", minimum: 3)
    expect(page).to have_css("select.select-menu-native", visible: :all, minimum: 3)
    expect(native("item_flagged")["tabindex"]).to eq("-1")
    expect(menu_button("item_flagged")).to have_text("false")
  end

  it "picks with the keyboard and writes the choice back to the select and the form" do
    liberia = create :warehouse, name: "Monrovia"
    create :shipment, name: "To Ghana", receiving_warehouse: create(:warehouse, name: "Accra")
    create :shipment, name: "To Liberia", receiving_warehouse: liberia
    visit_page shipments_path
    open_filters

    button = menu_button("f-receiver")
    button.send_keys(:down)
    expect(button["aria-expanded"]).to eq("true")
    open_list.find("[role=option]", text: "Monrovia").click

    expect(button).to have_text("Monrovia")
    expect(native("f-receiver").value).to eq(liberia.id.to_s)
    click_on "Apply"
    expect(page).to have_css("tbody tr", count: 1)
    expect(page).to have_text("To Liberia")
  end

  it "adds a search box to long lists that narrows the options" do
    11.times { |i| create :category, name: "Category #{i}" }
    create :category, name: "Dressings"
    visit_page items_path
    open_filters

    menu_button("f-category").click
    search = open_list.find(".select-menu-search")
    expect(search).to match_selector(":focus")
    search.send_keys("dress")

    expect(open_list).to have_css("[role=option]", count: 1, text: "Dressings")
    search.send_keys(:enter)
    expect(menu_button("f-category")).to have_text("Dressings")
  end

  it "says when nothing matches the search" do
    11.times { |i| create :category, name: "Category #{i}" }
    visit_page items_path
    open_filters
    menu_button("f-category").click
    open_list.find(".select-menu-search").send_keys("zzz")

    expect(open_list).to have_text("No matches")
  end

  describe "inside a modal" do
    before do
      create :box, pallet: nil, container: nil, status: Box::IN_PROGRESS
      visit_page boxes_path
      find("tbody input[type=checkbox]").click
      click_on "Mass Action"
      expect(page).to have_css("#mass-action-modal.show")
    end

    it "keeps other scripts working: choosing Box shows the box picker" do
      menu_button("item-assignment").click
      open_list.find("[role=option]", text: "Box", exact_text: true).click

      expect(page).to have_css("#box-assignment-form", visible: :visible)
      expect(native("item-assignment").value).to eq("Box")
    end

    it "closes just the list on Escape, leaving the modal open" do
      button = menu_button("item-assignment")
      button.click
      expect(page).to have_css(".select-menu-popup:not([hidden])")

      button.send_keys(:escape)
      expect(page).to have_no_css(".select-menu-popup:not([hidden])")
      expect(page).to have_css("#mass-action-modal.show")
      expect(button).to match_selector(":focus")
    end
  end
end
