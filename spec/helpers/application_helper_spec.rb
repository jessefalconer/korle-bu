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
end
