class Actions
  extend ActiveModel::Naming

  attr_reader :request, :donation

  delegate :student, :donor, :fulfiller, :book, to: :request

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

  def for_fulfiller?
    @user == fulfiller
  end

  def other_users
    [student, donor, fulfiller].compact - [@user]
  end

  def prompted_status
    if for_donor? || for_fulfiller?
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

  def relevant_actions
    if for_student?
      [
        :cancel_donation_not_received,
        :thank,
        :update_address,
        :message,
        :cancel_request,
      ]
    elsif for_donor?
      [
        :amazon_link,
        :flag,
        :message,
        :cancel_donation,
      ]
    elsif for_fulfiller?
      [
        :amazon_link,
        :flag,
        :message,
      ]
    else
      []
    end
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
    elsif for_donor? || for_fulfiller?
      case action
      when :amazon_link                   then donation.can_send? && book.amazon_url
      when :cancel_donation               then for_donor? && donation.donor_can_cancel?
      when :flag                          then donation.can_flag?
      end
    end
  end

  def other_actions
    relevant_actions.select {|action| available? action}
  end
end
