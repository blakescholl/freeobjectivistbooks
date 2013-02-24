class JoinUsersToLocations < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.rename :location, :location_deprecated
      t.references :location
    end
  end
end
