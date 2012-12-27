class AddDonorModeToDonations < ActiveRecord::Migration
  def up
    add_column :donations, :donor_mode, :string, null: false, default: "send_books"
    execute 'update donations d join users u on user_id=u.id set d.donor_mode = u.donor_mode where price_cents is not null'
  end

  def down
    remove_column :donations, :donor_mode
  end
end
