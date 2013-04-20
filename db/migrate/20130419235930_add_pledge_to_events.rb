class AddPledgeToEvents < ActiveRecord::Migration
  def change
    add_column :events, :pledge_id, :integer
    add_index :events, :pledge_id
  end
end
