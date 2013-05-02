class CreateFlags < ActiveRecord::Migration
  def change
    create_table :flags do |t|
      t.references :user
      t.references :donation
      t.string :type
      t.text :message
      t.boolean :fixed
      t.string :fix_type
      t.text :fix_message

      t.timestamps
    end
    add_index :flags, :user_id
    add_index :flags, :donation_id

    add_column :donations, :flag_id, :integer
    rename_column :donations, :flagged, :flagged_deprecated

    add_column :events, :flag_id, :integer
    add_index :events, :flag_id
  end
end
