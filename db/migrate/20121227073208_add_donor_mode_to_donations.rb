class AddDonorModeToDonations < ActiveRecord::Migration
  def up
    add_column :donations, :donor_mode, :string, null: false, default: "send_books"
    execute 'update donations d set donor_mode = u.donor_mode from users u where user_id=u.id and price_cents is not null'
  end

  def down
    remove_column :donations, :donor_mode
  end
end
