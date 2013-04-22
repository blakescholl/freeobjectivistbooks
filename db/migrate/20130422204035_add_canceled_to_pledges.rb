class AddCanceledToPledges < ActiveRecord::Migration
  def change
    add_column :pledges, :canceled, :boolean, null: false, default: false
  end
end
