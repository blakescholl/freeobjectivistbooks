ActiveAdmin.register User do
  actions :all, except: [:new, :destroy]

  member_action :spoof, method: :post do
    @user = User.find params[:id]
    set_current_user @user
    redirect_to profile_url
  end

  action_item only: :show do
    link_to "Spoof user", spoof_admin_user_path(user), method: :post
  end

  filter :name
  filter :email
  filter :studying
  filter :school
  filter :location_name, as: :string
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
      row :roles
      row :blocked
      row :created_at
      row :updated_at
    end
    panel "Contributions" do
      table_for user.contributions do
        column :created_at do |contribution|
          link_to I18n.l(contribution.created_at), admin2_contribution_path(contribution)
        end
        column(:amount) {|contribution| contribution.amount.format}
      end
      div do
        link_to "Add contribution", new_admin2_user_contribution_path(user), class: "button"
      end
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
      f.input :is_volunteer, as: :boolean
      f.input :blocked
    end
    f.actions
  end
end
