class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.references :user

      t.timestamps
    end
    add_index :orders, :user_id

    add_column :donations, :order_id, :integer
    add_index :donations, :order_id

    add_column :contributions, :order_id, :integer
    add_index :contributions, :order_id
  end
end
