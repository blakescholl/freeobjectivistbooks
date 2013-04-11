class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.references :user
      t.string :description
      t.integer :subtotal_cents
      t.integer :balance_applied_cents
      t.integer :total_cents

      t.timestamps
    end
    add_index :orders, :user_id

    change_table :donations do |t|
      t.references :order
    end
    add_index :donations, :order_id

    change_table :contributions do |t|
      t.references :order
    end
    add_index :contributions, :order_id
  end
end
