# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    # custom_uid: ordered on every index page, looked up by find_box/find_pallet,
    # read by maximum(:custom_uid) on every new record, and checked by the
    # uniqueness validation on every save (including cascades).
    # name: also checked by the uniqueness validation on every save.
    %i[boxes pallets containers shipments].each do |table|
      add_index table, :custom_uid, algorithm: :concurrently
      add_index table, :name, algorithm: :concurrently
    end

    # status: filtered by the staged/warehoused/in_progress/reassignable scopes and the cascades.
    add_index :boxes, :status, algorithm: :concurrently
    add_index :pallets, :status, algorithm: :concurrently
    add_index :containers, :status, algorithm: :concurrently
    add_index :packed_items, :status, algorithm: :concurrently
  end
end
