# frozen_string_literal: true

require "rails_helper"

describe ApplicationHelper, type: :helper do
  describe "#sorted_desc" do
    let(:pallet) { create :pallet, container: nil }
    let!(:boxes) do
      [3, 1, 2].map { |uid| create :box, pallet: pallet, container: nil, custom_uid: uid, name: "BOX-#{uid}" }
    end

    context "with a preloaded association" do
      let!(:loaded_pallet) { Pallet.preload(:boxes).find(pallet.id) }

      it "sorts newest-first without querying" do
        result = nil
        queries = count_queries { result = helper.sorted_desc(loaded_pallet.boxes, :custom_uid).map(&:custom_uid) }

        expect(result).to eq([3, 2, 1])
        expect(queries).to eq(0)
      end
    end

    context "with an unloaded relation" do
      it "orders in SQL and applies the preload" do
        relation = helper.sorted_desc(pallet.boxes, :custom_uid, preload: :user)

        expect(relation).to be_a(ActiveRecord::Relation)
        expect(relation.map(&:custom_uid)).to eq([3, 2, 1])
        expect(relation.preload_values).to eq([:user])
      end
    end
  end

  describe "#hospital_options" do
    let(:admin) { create :user, role: "Admin" }

    before do
      allow(helper).to receive(:current_ability).and_return(Ability.new(admin))
      create :hospital, name: "Zed Clinic"
      create :hospital, name: "Alpha Hospital"
    end

    it "renders option tags for accessible hospitals, sorted by name" do
      options = Nokogiri::HTML.fragment(helper.hospital_options).css("option").map(&:text)

      expect(options).to eq(["Alpha Hospital", "Zed Clinic"])
    end

    it "builds the options once per view and reuses them" do
      first = helper.hospital_options

      expect(count_queries { expect(helper.hospital_options).to equal(first) }).to eq(0)
    end
  end
end
