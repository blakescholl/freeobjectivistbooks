ActiveAdmin.register Book do
  filter :title
  filter :author
  filter :featured, as: :check_boxes

  config.sort_order = "title_asc"
end
