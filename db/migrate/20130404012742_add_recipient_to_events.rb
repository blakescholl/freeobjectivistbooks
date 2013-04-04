class AddRecipientToEvents < ActiveRecord::Migration
  def change
    change_table :events do |t|
      t.references :recipient
    end
  end
end
