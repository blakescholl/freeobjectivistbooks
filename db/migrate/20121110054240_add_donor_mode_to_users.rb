class AddDonorModeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :donor_mode, :string, null: false, default: "send_books"
  end
end
