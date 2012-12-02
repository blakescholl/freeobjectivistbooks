module EventMailerHelper
  def role_description(role)
    case role
    when :donor then "the donor"
    when :fulfiller then "Free Objectivist Books volunteer"
    end
  end
end
