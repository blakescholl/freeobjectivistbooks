ActiveAdmin.register Pledge do
  filter :user_name, as: :string
  filter :quantity

  index do
    selectable_column
    column :user
    column :quantity
    column(:recurring?) {|pledge| pledge.recurring? ? "every month" : "this month"}
    column(:active?) {|pledge| pledge.ended? ? "ended" : pledge.canceled? ? "canceled" : "active"}
    column(:status) {|pledge| pledge.status}
    default_actions
  end

  show do |pledge|
    attributes_table do
      row :user
      row(:summary) {|pledge| pledge_summary pledge}
      row :reason if pledge.reason.present?
      row(:active?) {|pledge| pledge.ended? ? "ended" : pledge.canceled? ? "canceled" : "active"}
      row(:status) {|pledge| "#{pledge.status} with #{pledge.donations_count} donations"}
      row :created_at
      row :updated_at
    end

    if pledge.events.any?
      panel "Events" do
        table_for pledge.events do
          column :user
          column(:what) {|event| (event.detail || event.type).humanize}
          column :happened_at
          column :message
        end
      end
    end

    active_admin_comments
  end
end
