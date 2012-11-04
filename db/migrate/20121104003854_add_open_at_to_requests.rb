class AddOpenAtToRequests < ActiveRecord::Migration
  def up
    add_column :requests, :open_at, :datetime
    execute "update requests set open_at = updated_at"
  end

  def down
    remove_column :requests, :open_at
  end
end
