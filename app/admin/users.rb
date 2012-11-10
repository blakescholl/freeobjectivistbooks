ActiveAdmin.register User do
  filter :name
  filter :email
  filter :studying
  filter :school
  filter :location
  filter :blocked

  index do
    selectable_column
    column :id
    column :name
    column :email
    column :studying
    column :school
    column :location
    column :blocked
    default_actions
  end

  show do |user|
    attributes_table do
      row :id
      row :name
      row :email
      row :studying
      row :school
      row :location
      row :address
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
      f.input :blocked
    end
    f.buttons
  end
end
