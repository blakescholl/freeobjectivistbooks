class CreateFulfillments < ActiveRecord::Migration
  def change
    create_table :fulfillments do |t|
      t.references :user
      t.references :donation

      t.timestamps
    end
    add_index :fulfillments, :user_id
    add_index :fulfillments, :donation_id
  end
end
