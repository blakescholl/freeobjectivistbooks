# Displays the logged-in-user homepage.
class ProfileController < ApplicationController
  before_filter :require_login

  def show
    @requests = @current_user.requests

    donations = @current_user.donations.active
    @show_donations = donations.any? || @current_user.pledges.any?

    send_books_donations = donations.send_books
    @needs_sending_donations = send_books_donations.needs_sending
    @flag_count = send_books_donations.not_sent.flagged.count

    @needs_payment_donations = donations.needs_payment
  end
end
