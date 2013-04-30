class CreateFlags < ActiveRecord::Migration
  def change
    create_table :flags do |t|
      t.references :user
      t.references :donation
      t.string :type
      t.text :message
      t.boolean :fixed

      t.timestamps
    end
    add_index :flags, :user_id
    add_index :flags, :donation_id

    add_column :donations, :flag_id, :integer
    rename_column :donations, :flagged, :flagged_deprecated
  end
end
