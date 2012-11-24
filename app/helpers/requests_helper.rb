module RequestsHelper
  def current_request
    @request || (@donation && @donation.request)
  end

  def current_donation
    @donation || (@request && @request.donation)
  end

  def current_student
    request = current_request
    request && request.user
  end

  def current_donor
    donation = current_donation
    donation && donation.user
  end

  def current_fulfiller
    donation = current_donation
    donation && donation.fulfiller
  end

  def current_is_donor?
    @current_user == current_donor
  end

  def current_is_student?
    @current_user == current_student
  end

  def current_is_fulfiller?
    @current_user == current_fulfiller
  end

  def other_user
    current_is_student? ? current_donor : current_student
  end
end
