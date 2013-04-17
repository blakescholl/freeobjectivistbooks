ActiveAdmin.register Contribution do
  # Workaround for ActiveAdmin problem as per https://github.com/gregbell/active_admin/issues/221
  controller.belongs_to :user, :order, polymorphic: true, optional: true

  actions :all, except: :edit

  filter :user_name, as: :string
  filter :amount_cents
  filter :created_at

  index do
    selectable_column
    column :user
    column(:amount) {|contribution| contribution.amount.format}
    column :order
    column(:created_at) {|contribution| I18n.l contribution.created_at}
    default_actions
  end

  show do |contribution|
    attributes_table do
      row :user
      row(:amount) {contribution.amount.format}
      row :order if contribution.order
      row(:transaction_id) {contribution.transaction_id}
      row :created_at
    end
    active_admin_comments
  end

  form do |f|
    f.inputs do
      f.input :user, collection: [f.object.user]
      f.input :order, collection: f.object.user.orders
      f.input :transaction_id, as: :string
      f.input :amount
    end
    f.actions
  end
end
