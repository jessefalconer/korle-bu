# frozen_string_literal: true

require "rails_helper"

# These columns are filtered, ordered or checked for uniqueness on hot paths
# (index pages, find_box/find_pallet, uniqueness validations, status scopes and cascades).
describe "Database indexes" do
  let(:connection) { ActiveRecord::Base.connection }

  {
    boxes: %i[custom_uid name status],
    pallets: %i[custom_uid name status],
    containers: %i[custom_uid name status],
    shipments: %i[custom_uid name],
    packed_items: %i[status]
  }.each do |table, columns|
    columns.each do |column|
      it "indexes #{table}.#{column}" do
        expect(connection.index_exists?(table, column)).to be(true)
      end
    end
  end
end
