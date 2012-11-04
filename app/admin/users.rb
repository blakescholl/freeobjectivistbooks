ActiveAdmin.register User do
  filter :name
  filter :email
  filter :studying
  filter :school
  filter :location

  index do
    selectable_column
    column :id
    column :name
    column :email
    column :studying
    column :school
    column :location
    default_actions
  end
end
