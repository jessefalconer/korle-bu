# frozen_string_literal: true

require "rake"
STATUS_TRANSLATIONS = {
  "packed": "Received",
  "packing": "In Progress"
}.freeze
# hp and ms-or are rewritten, check with Sean to the extent
CATEGORY_TRANSLATIONS = {
  "hp": "Hospital Pieces",
  "he":  "Hospital Equipment",
  "hm":  "Hospital Maintenance",
  "of":  "Office Furniture",
  "hl":  "Hospital Linen",
  "ms":  "Medical Supplies - Misc",
  "ms-oe":  "Medical Supplies - Ophthalmology & ENT",
  "ms-ns":  "Medical Supplies - Neuro Surgery",
  "ms-an":  "Medical Supplies - Anaesthesiology",
  "ms-or":  "Medical Supplies - Operating Room",
  "ms-pc":  "Medical Supplies - Pulmonary and Cardiology",
  "msns":  "Medical Supplies - Nursing Supplies",
  "ms-gi":  "Medical Supplies - Gastro, Intestinal and Urology",
  "ms-og":  "Medical Supplies - Obstetrics and Gynaecology",
  "ms-or":  "Medical Supplies - Orthopaedics",
  "ha":  "Hospital Administration",
  "hp":  "Hygiene Products",
  "spa":  "Staff Physical Activity Supplies",
  "sa":  "Staff Accomodation",
  "hkd":  "Housekeeping Department",
  "pws":  "Pediatrics",
  "bb":  "Bags Blankets"
}.freeze
SIZE_MAPPINGS = {
  "L": "Large",
  "S": "Small",
  "M": "Medium"
}.freeze

# Importing legacy data checklist
# • Legacy SQL dump should not alter and drop tables, only insert
# • legacy table and column names are a mix of snake and camel case, fix directly in file
# • hard reset schema if you get the pg relation error

namespace :legacy_data do
  task migrate: :environment do
    user_id = User.first.id
    # Legacy items are inserted to the new table without validation
    Item.all.update_all(user_id: user_id)

    # Boxes and Pallets receive a logical order of naming, custom IDs and standardized statuses
    Box.all.order(:created_at).each_with_index do |box, index|
      box.update_columns(user_id: user_id, name: "BOX-#{index + 1}", custom_uid: index + 1, status: box.status.titleize)
    end
    Pallet.all.order(:created_at).each_with_index do |pallet, index|
      pallet.update_columns(user_id: user_id, name: "PALLET-#{index + 1}", custom_uid: index + 1, status: "In Progress")
    end

    # Containers previously did not belong to a Shipment. Warehouses are seeded manually due to how few there are
    Container.all.order(:created_at).each_with_index do |container, index|
      shipping = Warehouse.find_by(name: "Main Warehouse")
      receiving = Warehouse.find_by(name: container.destination) || Warehouse.find_by(name: "Main Warehouse")
      status = STATUS_TRANSLATIONS[container.status&.to_sym] || "Not Started"

      ship = Shipment.create(user_id: user_id, name: "SHIPMENT-#{index + 1}", custom_uid: index + 1,
                              status: status, shipping_warehouse_id: shipping.id, receiving_warehouse_id: receiving.id,
                              created_at: container.created_at, updated_at: container.updated_at)

      container.update_columns(user_id: user_id, name: "CONTAINER-#{index + 1}", custom_uid: index + 1, status: status, shipment_id: ship.id)
    end

    # Move item box info to the STI PackedItem
    ItemBox.all.find_each do |ib|
      PackedItem.create(quantity: ib.quantity, weight: ib.weight,
                        expiry_date: ib.item_expire, box_id: ib.box_id,
                        item_id: ib.item_id, created_at: ib.created_at,
                        updated_at: ib.updated_at, user_id: user_id)
    end

    # Categories are manually seeded. Legacy data momoized hardcoded {String} into the record. Move these to a table and update
    Item.all.find_each do |item|
      cat = Category.find_by(name: CATEGORY_TRANSLATIONS[item.read_attribute(:category)&.to_sym])
      item.update_columns(generated_name: item.object, category_id: cat&.id)
    end

    # BigItem previously was simultaneously an {Item} and a {ItemBox} except for {Container}s. Break these out to distinct items
    # and send the rest of the attributes to the {PackedItem} join table.
    BigItem.all.find_each do |bi|
      cat = Category.find_by(name: CATEGORY_TRANSLATIONS[bi.category&.to_sym])
      item = Item.find_or_create_by(object: bi.description.squish, category_id: cat&.id, user_id: user_id)

      PackedItem.create(quantity: 1, weight: bi.weight, container_id: bi.container_id,
                        item_id: item.id, created_at: bi.created_at,
                        updated_at: bi.updated_at, user_id: user_id)
    end
  end

  task reshape_data: :environment do
    Item.all.find_each do |item|
      # check if we can move some sizes out of the base name
      name = item.object.squish.upcase
      Item::STANDARD_SIZES.each do |size|
        if name.include? size.upcase
          item.update(object: name.gsub(size.upcase, "").squish.titleize, standardized_size: size)
        end
      end
      regex = /\A[SML]\s|\s[SML]$|\s[SML]\s/
      if name.match regex
        match = name.match regex
        item.update(object: name.gsub(match[0], "").squish.titleize, standardized_size: SIZE_MAPPINGS[match[0].to_sym])
      end

      # TODO: check if we can move some quantities out of the base name
    end
  end

  task link_packed_items: :environment do
    PackedItem.find_each do |item|
      shipment = item.box&.container&.shipment || item.pallet&.container&.shipment || item.box&.container&.shipment || item.container&.shipment
      next if shipment.nil?

      item.update(shipment_id: shipment.id)
    end
  end

  task prune_data: :environment do
    counter = 0
    Item.all.find_each do |item|
      if Item.item_instances(item).zero?
        item.destroy
        counter += 1
        puts "Destroyed #{counter} items"
        next
      end
    end
  end
end
