class AddPriceToBooks < ActiveRecord::Migration
  def change
    add_column :books, :price_cents, :integer
  end
end
