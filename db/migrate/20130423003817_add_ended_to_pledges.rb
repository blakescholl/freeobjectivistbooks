class AddEndedToPledges < ActiveRecord::Migration
  def change
    add_column :pledges, :ended, :boolean, null: false, default: false
  end
end
