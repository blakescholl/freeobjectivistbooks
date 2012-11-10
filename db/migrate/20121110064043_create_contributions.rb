class CreateContributions < ActiveRecord::Migration
  def change
    create_table :contributions do |t|
      t.references :user
      t.integer :amount_cents, null: false

      t.timestamps
    end
    add_index :contributions, :user_id
  end
end
