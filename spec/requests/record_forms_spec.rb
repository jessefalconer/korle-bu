# frozen_string_literal: true

require "rails_helper"

# Boxes, pallets, containers and shipments get their name and Custom ID assigned on
# create (set_defaults in each model), so the "new" form shows them read-only. Once the
# record exists, the edit form (in the show page's Edit modal) lets you change them.
describe "Box, pallet, container and shipment forms", type: :request do
  let(:admin) { create :user, status: "Active", role: "Admin" }

  before { sign_in admin }

  # Scoped to the record's own form: the Jump To modal on every page also has
  # box[custom_uid] and pallet[custom_uid] inputs for looking records up
  def field(html, attribute, model)
    Nokogiri::HTML(html).at_css("form.new_#{model} input[name='#{model}[#{attribute}]'], " \
                                "form.edit_#{model} input[name='#{model}[#{attribute}]']")
  end

  def status_select(html, model)
    Nokogiri::HTML(html).at_css("form.new_#{model} select[name='#{model}[status]'], " \
                                "form.edit_#{model} select[name='#{model}[status]']")
  end

  # Containers and shipments always start In Progress, so their status is fixed on
  # "new"; boxes and pallets keep the status picked on the form.
  { box: false, pallet: false, container: true, shipment: true }.each do |model, locked|
    it "#{locked ? "locks" : "leaves editable"} the status on a new #{model}" do
      get public_send(:"new_#{model}_path")

      expect(status_select(response.body, model)["disabled"].present?).to eq(locked)
    end
  end

  {
    box: [-> { new_box_path }, -> { box_path(create(:box)) }],
    pallet: [-> { new_pallet_path }, -> { pallet_path(create(:pallet)) }],
    container: [-> { new_container_path }, -> { container_path(create(:container)) }],
    shipment: [-> { new_shipment_path }, -> { shipment_path(create(:shipment)) }]
  }.each do |model, (new_path, show_path)|
    describe model.to_s do
      it "shows the assigned name and Custom ID read-only when creating" do
        get instance_exec(&new_path)

        expect(response).to have_http_status(:ok)
        expect(field(response.body, :name, model)["readonly"]).to be_present
        expect(field(response.body, :name, model)["value"]).to match(/\A#{model.to_s.upcase}-\d+\z/)
        expect(field(response.body, :custom_uid, model)["readonly"]).to be_present
      end

      it "lets you edit the name and Custom ID once created" do
        get instance_exec(&show_path)

        expect(response).to have_http_status(:ok)
        expect(field(response.body, :name, model)["readonly"]).to be_nil
        expect(field(response.body, :custom_uid, model)["readonly"]).to be_nil
        expect(status_select(response.body, model)["disabled"]).to be_nil
      end
    end
  end
end
