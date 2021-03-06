ActiveAdmin.register Book do
  filter :title
  filter :author
  filter :featured, as: :check_boxes

  config.sort_order = "title_asc"

  index do
    selectable_column
    column :title
    column :author
    column :featured
    column :rank
    column(:price) {|book| book.price.format if book.price}
    default_actions
  end

  show title: :title do |book|
    attributes_table do
      row :title
      row :author
      row :featured
      row :rank
      row(:asin) {link_to book.asin, book.amazon_url}
      row(:price) {book.price.format if book.price}
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |f|
    f.inputs do
      f.input :title
      f.input :author
      f.input :featured
      f.input :rank
      f.input :asin, label: "ASIN"
      f.input :price
    end
    f.actions
  end
end
