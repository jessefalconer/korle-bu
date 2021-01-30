class EnableTrignamSearchOnGeneratedName < ActiveRecord::Migration[6.0]
  def change
    enable_extension :pg_trgm

    add_index :items, :generated_name, opclass: :gin_trgm_ops, using: :gin
  end
end
