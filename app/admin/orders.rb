ActiveAdmin.register Order do
  actions :index, :show

  filter :user_name, as: :string
  filter :created_at

  index do
    selectable_column
    column :user
    column :description
    column(:total) {|order| order.total.format}
    column :paid?
    column :created_at
    default_actions
  end

  show do |order|
    attributes_table do
      row :user
      row :description
      row(:total) {order.total.to_money.format}
      row :paid?
      row :created_at
    end

    panel "Donations" do
      table_for order.donations do
        column :student
        column :book
        column(:price) {|donation| donation.price.format}
        column(:view_request) {|donation| link_to "View request", admin2_request_path(donation.request)}
      end
    end

    panel "Contributions" do
      table_for order.contributions do
        column :created_at
        column(:amount) {|contribution| contribution.amount.format}
        column(:view) {|contribution| link_to "View", admin2_contribution_path(contribution)}
      end
      div do
        link_to "Add contribution", new_admin2_order_contribution_path(order), class: "button"
      end
    end

    active_admin_comments
  end
end
