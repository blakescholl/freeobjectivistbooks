ActiveAdmin.register Contribution do
  belongs_to :user, optional: true

  actions :all, except: :edit

  index do
    selectable_column
    column :user
    column(:amount) {|contribution| contribution.amount.format}
    column(:created_at) {|contribution| I18n.l contribution.created_at}
    default_actions
  end

  show do |contribution|
    attributes_table do
      row :user
      row(:amount) {contribution.amount.format}
      row :created_at
    end
    active_admin_comments
  end

  form do |f|
    f.inputs do
      f.input :user
      f.input :amount
    end
    f.actions
  end
end
