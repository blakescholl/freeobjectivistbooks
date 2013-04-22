class AddPledgeToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :pledge_id, :integer
  end
end
