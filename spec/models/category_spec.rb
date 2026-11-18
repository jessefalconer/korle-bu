# frozen_string_literal: true

require "rails_helper"

describe Category do
  subject { create :category }

  it "requires a user" do
    expect(build(:category, user: nil)).not_to be_valid
  end

  it "has many items" do
    item = create :item, category: subject
    create :item

    expect(subject.items).to contain_exactly(item)
  end

  it "has many pallets" do
    pallet = create :pallet, category: subject
    expect(subject.pallets).to contain_exactly(pallet)
  end
end
