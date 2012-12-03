module AdminHelper
  def admin_user_link(user)
    link_to user.name, admin_user_path(user)
  end

  def admin_user_links(users)
    users = Array(users).flatten.compact
    links = users.map {|user| admin_user_link user}
    links.to_sentence
  end
end
