class AddReplyToEventToEvents < ActiveRecord::Migration
  def change
    change_table :events do |t|
      t.references :reply_to_event
    end
  end
end
