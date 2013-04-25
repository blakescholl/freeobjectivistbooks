require 'test_helper'

class Admin::DonationsControllerTest < ActionController::TestCase
  test "show" do
    get :show, {id: @quentin_donation.id}, session_for(users :admin)
    assert_redirected_to [:admin, @quentin_request]
  end
end
