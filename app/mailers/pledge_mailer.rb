class PledgeMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper
  include PledgeHelper

  def pledge_rotation(pledge)
    @user = pledge.user
    @pledge = pledge
    @feedback = feedback_for pledge
    @request_count = Request.not_granted.count

    subject = case pledge.status
    when :exceeded
      "You exceeded your pledge of #{pluralize pledge.quantity, 'book'} on Free Objectivist Books!"
    when :fulfilled
      "Thank you for fulfilling your pledge of #{pluralize pledge.quantity, 'book'} on Free Objectivist Books"
    else
      "Your pledge on Free Objectivist Books is up"
    end

    mail_to_user @user, subject: subject
  end
end
