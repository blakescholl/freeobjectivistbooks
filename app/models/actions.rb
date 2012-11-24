class Actions
  extend ActiveModel::Naming

  attr_reader :request, :donation

  delegate :student, :donor, :book, to: :request

  def initialize(request, user)
    @user = user
    @request = request
    @donation = request.donation
  end

  def for_student?
    @user == student
  end

  def for_donor?
    @user == donor
  end

  def prompted_status
    if for_donor?
      if donation.can_send?
        :sent
      end
    elsif for_student? && request.granted?
      if !donation.received?
        :received
      elsif !donation.read?
        :read
      end
    end
  end

  def donor_actions
    [
      :amazon_link,
      :flag,
      :message,
      :cancel_donation,
    ]
  end

  def student_actions
    [
      :cancel_donation_not_received,
      :thank,
      :update_address,
      :message,
      :cancel_request,
    ]
  end

  def available?(action)
    if action == :message
      donation.present?
    elsif for_student?
      case action
      when :cancel_donation_not_received  then donation && donation.student_can_cancel?
      when :cancel_request                then request.can_cancel?
      when :thank                         then request.needs_thanks?
      when :update_address                then !request.sent?
      end
    elsif for_donor?
      case action
      when :amazon_link                   then donation.can_send? && book.amazon_url
      when :cancel_donation               then donation.donor_can_cancel?
      when :flag                          then donation.can_flag?
      end
    end
  end

  def other_actions
    actions = for_donor? ? donor_actions : for_student? ? student_actions : []
    actions.select {|action| available? action}
  end
end
