ActiveAdmin.register User do
  filter :name
  filter :email
  filter :studying
  filter :school
  filter :location
  filter :donor_mode
  filter :blocked, as: :check_boxes

  index do
    selectable_column
    column :name
    column :email
    column :location
    default_actions
  end

  show do |user|
    attributes_table do
      row :name
      row :email
      row :studying
      row :school
      row :location
      row :address
      row(:donor_mode) {user.donor_mode.humanize}
      row(:balance) {humanized_money_with_symbol user.balance}
      row :blocked
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :studying
      f.input :school
      f.input :location
      f.input :address
      f.input :donor_mode, as: :radio, collection: User::DONOR_MODES
      f.input :blocked
    end
    f.buttons
  end
end
