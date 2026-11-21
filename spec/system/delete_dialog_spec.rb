# frozen_string_literal: true

require "rails_helper"

# src/confirm_dialog.js: the in-app confirm, and typing "delete" for records
# that hold or organize others.
describe "Delete confirmation dialog", type: :system do
  let(:admin) { create :user, status: "Active", role: "Admin" }

  before { log_in_as admin }

  def dialog
    find("#confirm-dialog")
  end

  def accept_button
    dialog.find(".confirm-dialog-accept")
  end

  describe "a record that needs \"delete\" typed" do
    let!(:container) { create :container, name: "CONTAINER-TEST" }

    before do
      create :box, container: container, pallet: nil
      visit_page container_path(container)
      click_on "Delete"
    end

    it "lists what else changes and keeps Delete disabled until the word is typed" do
      expect(dialog).to have_text("Its 1 box will be unassigned from it, not deleted.")
      word = dialog.find("#confirm-dialog-word")
      expect(word).to match_selector(":focus")
      expect(accept_button).to be_disabled

      word.send_keys("delet")
      expect(accept_button).to be_disabled
      word.send_keys("E")
      expect(accept_button).not_to be_disabled
    end

    it "deletes on Enter once the word matches" do
      dialog.find("#confirm-dialog-word").send_keys("delete", :enter)

      expect(page).to have_text("Container deleted.")
      expect(Container.exists?(container.id)).to be(false)
    end

    it "does nothing on Enter while the word is wrong, or on Cancel" do
      word = dialog.find("#confirm-dialog-word")
      word.send_keys("nope", :enter)
      expect(page).to have_css("#confirm-dialog[open]")

      dialog.click_on "Cancel"
      expect(page).to have_no_css("#confirm-dialog[open]")
      expect(Container.exists?(container.id)).to be(true)
    end
  end

  it "is a single confirm for a box that isn't received" do
    box = create :box, pallet: nil, container: nil, status: Box::IN_PROGRESS
    visit_page box_path(box)
    click_on "Delete"

    expect(dialog).to have_no_css(".confirm-dialog-typed", visible: :visible)
    expect(accept_button).not_to be_disabled
    accept_button.click

    expect(page).to have_text("Box deleted.")
    expect(Box.exists?(box.id)).to be(false)
  end
end
