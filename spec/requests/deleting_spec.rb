# frozen_string_literal: true

require "rails_helper"

# Records that hold or organize others need "delete" typed in the confirm dialog,
# and anything still in use can't be deleted at all. The server checks both.
describe "Deleting", type: :request do
  let(:admin) { create :user, status: "Active", role: "Admin" }
  let(:warehouse) { create :warehouse }
  let(:typed) { { confirm_delete: "delete" } }

  before { sign_in admin }

  def loose_item(item = create(:item))
    create :packed_item, item: item, box: nil, pallet: nil, container: nil, shipment: nil, status: PackedItem::STAGED
  end

  describe "records that need \"delete\" typed" do
    it "refuses a container delete without it, and explains" do
      container = create :container

      expect { delete container_path(container) }.not_to change(Container, :count)
      expect(response).to redirect_to(container_path(container))
      expect(flash[:error]).to eq("Type \"delete\" to confirm deleting #{container.name}.")
    end

    it "deletes once it's typed, in any letter case" do
      container = create :container

      expect { delete container_path(container), params: { confirm_delete: " Delete " } }.to change(Container, :count).by(-1)
    end

    it "always applies to items and shipments" do
      item = create :item
      shipment = create :shipment

      delete item_path(item)
      delete shipment_path(shipment)
      expect([Item.exists?(item.id), Shipment.exists?(shipment.id)]).to eq([true, true])

      delete item_path(item), params: typed
      delete shipment_path(shipment), params: typed
      expect([Item.exists?(item.id), Shipment.exists?(shipment.id)]).to eq([false, false])
    end

    it "applies to boxes and pallets only once they're received" do
      packing_box = create :box, pallet: nil, container: nil, status: Box::IN_PROGRESS
      create :packed_item, box: packing_box, pallet: nil, container: nil, shipment: nil
      packing_pallet = create :pallet, container: nil, status: Pallet::IN_PROGRESS
      received_box = create :box, pallet: nil, container: nil, status: Box::RECEIVED
      received_pallet = create :pallet, container: nil, status: Pallet::RECEIVED

      expect { delete box_path(packing_box) }.to change(Box, :count).by(-1)
      expect { delete pallet_path(packing_pallet) }.to change(Pallet, :count).by(-1)
      expect { delete box_path(received_box) }.not_to change(Box, :count)
      expect { delete pallet_path(received_pallet) }.not_to change(Pallet, :count)
      expect { delete box_path(received_box), params: typed }.to change(Box, :count).by(-1)
      expect { delete pallet_path(received_pallet), params: typed }.to change(Pallet, :count).by(-1)
    end
  end

  describe "records still in use" do
    it "keeps a hospital that has unpacking records, even with \"delete\" typed" do
      hospital = create :hospital
      create :unpacking_event, packed_item: loose_item, hospital: hospital

      expect { delete hospital_path(hospital), params: typed }.not_to change(Hospital, :count)
      expect(flash[:error]).to eq("#{hospital.name} can't be deleted: it has 1 unpacking record.")
    end

    it "keeps a category that items use" do
      category = create :category
      create :item, category: category

      expect { delete category_path(category) }.not_to change(Category, :count)
      expect(flash[:error]).to include("1 item use it")
    end

    it "keeps someone who has created records" do
      packer = create :user, status: "Active", role: "Volunteer"
      loose_item.update!(user: packer)

      expect { delete user_path(packer) }.not_to change(User, :count)
    end

    it "still deletes an unused hospital with a single confirm" do
      hospital = create :hospital

      expect { delete hospital_path(hospital) }.to change(Hospital, :count).by(-1)
    end
  end

  describe "the Delete buttons" do
    it "ask for the word and list what else changes on a container's page" do
      container = create :container
      create :box, container: container, pallet: nil
      create :pallet, container: container
      get container_path(container)

      button = response.parsed_body.at_css("a[data-method='delete']")
      expect(button["data-confirm-word"]).to eq("delete")
      expect(JSON.parse(button["data-confirm-details"])).to eq(["Its 1 pallet and 1 box will be unassigned from it, not deleted."])
    end

    it "leave a box that isn't received as a single confirm, even with items in it" do
      box = create :box, pallet: nil, container: nil, status: Box::IN_PROGRESS
      create :packed_item, box: box, pallet: nil, container: nil, shipment: nil
      get box_path(box)

      expect(response.parsed_body.at_css("a[data-method='delete']")["data-confirm-word"]).to be_nil
    end

    it "ask for the word on a received pallet's page" do
      pallet = create :pallet, container: nil, status: Pallet::RECEIVED
      get pallet_path(pallet)

      expect(response.parsed_body.at_css("a[data-method='delete']")["data-confirm-word"]).to eq("delete")
    end
  end

  describe "what deleting leaves behind" do
    let(:shipment) { create :shipment, receiving_warehouse: warehouse }
    let(:container) { create :container, shipment: shipment }

    def received_box_item
      box = create :box, container: container, pallet: nil
      create(:packed_item, box: box, pallet: nil, container: nil, quantity: 4).tap do
        shipment.update!(status: Shipment::RECEIVED)
      end
    end

    it "takes a deleted container's boxes out of received stock" do
      packed = received_box_item
      expect(PackedItem.received_in(warehouse.id)).to include(packed)

      delete container_path(container), params: typed

      expect(packed.reload.shipment_id).to be_nil
      expect(PackedItem.received_in(warehouse.id)).not_to include(packed)
    end

    it "takes a deleted shipment's contents out of received stock" do
      packed = received_box_item

      delete shipment_path(shipment), params: typed

      expect(packed.reload.shipment_id).to be_nil
      expect(PackedItem.received_in(warehouse.id)).not_to include(packed)
    end

    it "takes a deleted pallet's boxes out of received stock" do
      pallet = create :pallet, container: container
      box = create :box, pallet: pallet, container: nil
      packed = create :packed_item, box: box, pallet: nil, container: nil, quantity: 2
      shipment.update!(status: Shipment::RECEIVED)
      expect(packed.reload.shipment_id).to eq(shipment.id)

      delete pallet_path(pallet), params: typed

      expect(packed.reload.shipment_id).to be_nil
    end
  end
end
