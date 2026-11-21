# frozen_string_literal: true

require "rails_helper"

describe Item do
  subject { create :item, user: user }

  let(:user) { create :user }

  describe "item naming" do
    it "generates a formatted name based on multiple components" do
      subject.update(object: "Syringe", numerical_units_1: "mL", numerical_description_1: "Tube", numerical_size_1: 15.000)
      expect(subject.generated_name).to eq("Syringe 15mL Tube")
    end

    it "removes unwanted whitespace" do
      subject.update(object: " Topical   solution")
      expect(subject.generated_name).to eq("Topical solution")
    end
  end

  describe "#process_name" do
    it "includes brand and standardized size" do
      item = create :item, brand: "BD", object: "Syringe", standardized_size: "Adult Small"
      expect(item.generated_name).to eq("BD Syringe Adult Small")
    end

    it "includes both numerical phrases" do
      item = create :item, object: "Needle", numerical_size_1: 22.0, numerical_units_1: "ga",
                           numerical_size_2: 2.5, numerical_units_2: "cm", numerical_description_2: "length"
      expect(item.generated_name).to eq("Needle 22ga 2.5cm Length")
    end

    it "includes area and range phrases" do
      item = create :item, object: "Bandage", area_1: 10.0, area_2: 10.0, area_units: "cm",
                           area_description: "gauze", range_1: 1.0, range_2: 3.0, range_units: "kg"
      expect(item.generated_name).to eq("Bandage 10x10cm Gauze 1-3kg")
    end

    it "omits an area unless both dimensions are present" do
      item = create :item, object: "Gauze", area_1: 5.0, area_units: "cm"
      expect(item.generated_name).to eq("Gauze")
    end

    it "omits a range unless both bounds are present" do
      item = create :item, object: "Scale", range_2: 100.0, range_units: "kg"
      expect(item.generated_name).to eq("Scale")
    end

    it "falls back to 'Unnamed Item' when nothing is given" do
      item = create :item, object: ""
      expect(item.generated_name).to eq("Unnamed Item")
    end

    it "titleizes descriptions" do
      item = create :item, object: "Saline", numerical_size_1: 500.0, numerical_units_1: "mL",
                           numerical_description_1: "iv bag"
      expect(item.generated_name).to eq("Saline 500mL Iv Bag")
    end
  end

  describe "#strip_trailing_zero" do
    it "removes trailing decimal zeros" do
      expect(subject.strip_trailing_zero(15.0)).to eq("15")
      expect(subject.strip_trailing_zero(2.50)).to eq("2.5")
      expect(subject.strip_trailing_zero(0.125)).to eq("0.125")
    end

    it "keeps significant zeros in whole floats" do
      expect(subject.strip_trailing_zero(100.0)).to eq("100")
    end
  end

  describe "validations" do
    it "requires a unique generated name" do
      create :item, object: "Gloves"
      expect(build(:item, object: "Gloves")).not_to be_valid
    end

    it "treats names differing only by whitespace as duplicates" do
      create :item, object: "Exam Gloves"
      expect(build(:item, object: "  Exam    Gloves ")).not_to be_valid
    end

    it "requires a user" do
      expect(build(:item, user: nil)).not_to be_valid
    end
  end

  describe "#trigram" do
    it "returns no trigrams for a blank word" do
      expect(subject.trigram("   ")).to eq([])
    end

    it "pads and downcases the word" do
      expect(subject.trigram("Ab")).to eq(["  a", " ab", "ab "])
    end
  end

  describe "#name_similarity" do
    it "is 100 for identical names" do
      a = create :item, object: "Surgical Mask"
      b = build :item, object: "Surgical Mask"
      b.valid?

      expect(a.name_similarity(b)).to eq(100.0)
    end

    it "ranks closer names higher" do
      base = create :item, object: "Surgical Mask"
      close = create :item, object: "Surgical Masks"
      far = create :item, object: "Wheelchair"

      expect(base.name_similarity(close)).to be > base.name_similarity(far)
      expect(base.name_similarity(far)).to be_between(0.0, 100.0)
    end
  end

  describe "scopes" do
    let(:category) { create :category }
    let!(:verified) { create :item, verified: true, category: category }
    let!(:flagged) { create :item, flagged: true }

    it "filters by verification" do
      expect(Item.verified).to contain_exactly(verified)
      expect(Item.unverified).to contain_exactly(flagged)
    end

    it "filters by category" do
      expect(Item.categorized).to contain_exactly(verified)
      expect(Item.uncategorized).to contain_exactly(flagged)
    end

    it "filters by flag" do
      expect(Item.flagged).to contain_exactly(flagged)
      expect(Item.not_flagged).to contain_exactly(verified)
    end
  end

  describe ".execute_merge" do
    let(:target) { create :item, object: "Gauze" }
    let(:duplicate) { create :item, object: "Gauze Pad" }
    let!(:packed_item) do
      create :packed_item, item: duplicate, box: nil, pallet: nil, container: nil, status: PackedItem::WAREHOUSED
    end

    it "moves packed items to the target and verifies it" do
      Item.execute_merge(target, [duplicate])

      expect(packed_item.reload.item).to eq(target)
      expect(target.reload).to be_verified
      expect(Item.exists?(duplicate.id)).to be(true)
    end

    it "deletes merged items when asked" do
      Item.execute_merge(target, [duplicate], delete: true)

      expect(Item.exists?(duplicate.id)).to be(false)
      expect(packed_item.reload.item).to eq(target)
    end

    it "does not verify the target when verify is false" do
      Item.execute_merge(target, [duplicate], verify: false)
      expect(target.reload).not_to be_verified
    end

    it "never deletes the target, even if it is listed among the duplicates" do
      Item.execute_merge(target, [duplicate, target], delete: true)

      expect(Item.exists?(target.id)).to be(true)
      expect(packed_item.reload.item).to eq(target)
    end

    it "changes nothing if any part of the merge fails" do
      allow_any_instance_of(Item).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

      expect { Item.execute_merge(target, [duplicate], delete: true) }.to raise_error(ActiveRecord::RecordNotDestroyed)
      expect(packed_item.reload.item).to eq(duplicate)
    end
  end

  describe "serial numbers" do
    it "puts the S/N at the end of the name" do
      item = create :item, brand: "Stryker FL28C", object: "Hospital Bed", serial_number: " R20722 "

      expect(item.serial_number).to eq("R20722")
      expect(item.generated_name).to eq("Stryker FL28C Hospital Bed S/N R20722")
    end

    it "keeps otherwise identical items apart by serial" do
      create :item, object: "Hospital Bed", serial_number: "A1"

      expect(build(:item, object: "Hospital Bed", serial_number: "B2")).to be_valid
      expect(build(:item, object: "Hospital Bed", serial_number: "A1")).not_to be_valid
    end

    it "leaves names without a serial unchanged" do
      expect(create(:item, object: "Gauze").generated_name).to eq("Gauze")
    end
  end
end
