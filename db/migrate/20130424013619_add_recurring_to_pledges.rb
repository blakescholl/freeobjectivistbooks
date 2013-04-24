class AddRecurringToPledges < ActiveRecord::Migration
  def change
    add_column :pledges, :recurring, :boolean, null: false, default: false
  end
end
