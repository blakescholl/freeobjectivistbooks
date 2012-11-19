class AddPriceAndPaidToDonations < ActiveRecord::Migration
  def change
    change_table :donations do |t|
      t.integer :price_cents
      t.boolean :paid, null: false, default: false
    end
  end
end
