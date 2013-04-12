class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.references :user
      t.string :description
      t.integer :total_cents
      t.integer :balance_applied_cents
      t.integer :new_contribution_cents

      t.timestamps
    end
    add_index :orders, :user_id

    add_column :donations, :order_id, :integer
    add_index :donations, :order_id

    add_column :contributions, :order_id, :integer
    add_index :contributions, :order_id
  end
end
