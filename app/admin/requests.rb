ActiveAdmin.register Request do
  actions :index, :show

  filter :user_name, as: :string
  filter :book_title, as: :string
  filter :donation_user_name, as: :string

  index do
    selectable_column
    column :student
    column :book
    column :donor
    column(:status) {|request| status_headline request}
    default_actions
  end

  show do |request|
    attributes_table do
      row :student
      row :book
      row :reason
      if request.open?
        row :open_at
      else
        row :donor if request.donor.present?
        row (:status) {status_headline request}
        row :thanked?
      end
      row :referral if request.referral
      row :created_at
      row :updated_at
    end

    if request.review
      panel "Review" do
        para {request.review.text}
        strong {request.review.recommend? ? "Would recommend to others" : "Would NOT recommend to others"}
      end
    end

    panel "Events" do
      table_for request.events do
        column :user
        column(:what) {|event| (event.detail || event.type).humanize}
        column :happened_at
        column :message
      end
    end

    if request.donation
      panel "Reminders" do
        table_for request.donation.reminders do
          column :user
          column(:type) {|reminder| reminder.class.type_name.humanize}
          column :subject
          column :created_at
        end
      end
    end

    active_admin_comments
  end
end
