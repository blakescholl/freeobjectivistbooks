class AddRefundedToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :refunded, :boolean, null: false, default: false
  end
end
