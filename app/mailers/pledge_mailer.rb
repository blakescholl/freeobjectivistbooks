class PledgeMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper
  include PledgeHelper

  def pledge_ended(pledge)
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

  def pledge_autorenewed(pledge, new_pledge)
    @user = pledge.user
    @pledge = pledge
    @new_pledge = new_pledge
    @feedback = feedback_for pledge
    @request_count = Request.not_granted.count

    subject = case pledge.status
    when :exceeded
      "You exceeded your pledge of #{pluralize pledge.quantity, 'book'} on Free Objectivist Books this month!"
    when :fulfilled
      "Thank you for fulfilling your pledge of #{pluralize pledge.quantity, 'book'} on Free Objectivist Books this month"
    else
      "It's a new month, want to spread Objectivism through Free Objectivist Books?"
    end

    mail_to_user @user, subject: subject
  end
end
