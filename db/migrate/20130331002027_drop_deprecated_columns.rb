class DropDeprecatedColumns < ActiveRecord::Migration
  def up
    change_table :requests do |t|
      t.remove :book_deprecated
      t.remove :donor_id_deprecated
      t.remove :flagged_deprecated
      t.remove :thanked_deprecated
      t.remove :status_deprecated
    end

    remove_column :events, :donor_id_deprecated

    remove_column :reviews, :book_deprecated

    remove_column :users, :location_deprecated
  end

  def down
    change_table :requests do |t|
      t.string :book_deprecated
      t.integer :donor_id_deprecated
      t.boolean :flagged_deprecated
      t.boolean :thanked_deprecated
      t.string :status_deprecated
    end

    add_column :events, :donor_id_deprecated, :integer

    add_column :reviews, :book_deprecated, :string

    add_column :users, :location_deprecated, :string
  end
end
