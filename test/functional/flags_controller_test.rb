require 'test_helper'

class FlagsControllerTest < ActionController::TestCase
  # New

  test "new" do
    get :new, {donation_id: @quentin_donation.id}, session_for(@hugh)
    assert_response :success
    assert_select 'h1', /flag/i
    assert_select '.address', /123 Main St/
    assert_select 'p', /We'll send your message to Quentin/
    assert_select 'textarea#flag_message'
    assert_select 'input[type="submit"]'
  end

  test "new for fulfiller" do
    @frisco_donation.fulfill @kira
    get :new, {donation_id: @frisco_donation.id}, session_for(@kira)
    assert_response :success
  end

  test "new requires login" do
    get :new, donation_id: @quentin_donation.id
    verify_login_page
  end

  test "new requires sender" do
    get :new, {donation_id: @quentin_donation.id}, session_for(@howard)
    verify_wrong_login_page
  end

  # Create

  def verify_flagged(donation, user, message)
    donation.reload
    assert donation.flagged?

    flag = donation.flag
    assert_equal user, flag.user
    assert_equal donation, flag.donation
    assert_equal 'shipping_info', flag.type
    assert_equal message, flag.message

    verify_event donation, "flag", user: user, notified?: true
  end

  test "create" do
    assert_difference "@quentin_donation.events.count" do
      post :create, {donation_id: @quentin_donation.id, flag: {message: "Fix this"}}, session_for(@hugh)
    end

    assert_redirected_to @quentin_request
    assert_match /sent to Quentin Daniels/i, flash[:notice]

    verify_flagged @quentin_donation, @hugh, "Fix this"
  end

  test "create by fulfiller" do
    @frisco_donation.fulfill @kira
    assert_difference "@frisco_donation.events.count" do
      params = {donation_id: @frisco_donation.id, flag: {message: "Fix this"}, redirect: volunteer_url}
      post :create, params, session_for(@kira)
    end

    assert_redirected_to volunteer_url
    assert_match /sent to Francisco d'Anconia/i, flash[:notice]

    verify_flagged @frisco_donation, @kira, "Fix this"
  end

  test "create requires message" do
    assert_no_difference "@quentin_donation.events.count" do
      post :create, {donation_id: @quentin_donation.id, flag: {message: ""}}, session_for(@hugh)
    end

    assert_response :success
    assert_select 'h1', /flag/i

    @quentin_donation.reload
    assert !@quentin_donation.flagged?
  end

  test "create requires login" do
    post :create, {donation_id: @quentin_donation.id, flag: {message: "Fix this"}}
    verify_login_page
  end

  test "create requires donor" do
    post :create, {donation_id: @quentin_donation.id, flag: {message: "Fix this"}}, session_for(@howard)
    verify_wrong_login_page
  end

  # Fix

  test "fix" do
    flag = create :flag
    get :fix, {id: flag.id}, session_for(flag.student)
    assert_response :success
    assert_select '.message.error .headline', /problem/
    assert_select '.message.error .detail', /Donor \d+ says: "Please correct your address"/
    assert_select 'input#flag_student_name[value=?]', flag.student_name
    assert_select 'textarea#flag_address', flag.address
    assert_select 'textarea#flag_fix_message'
    assert_select 'input[type="submit"]'
  end

  test "fix flag from fulfiller" do
    fulfillment = create :fulfillment
    fulfillment.donation.flag!
    flag = fulfillment.donation.flag

    get :fix, {id: flag.id}, session_for(flag.student)
    assert_response :success
    assert_select '.message.error .headline', /problem/
    assert_select '.message.error .detail', /Volunteer \d+ says: /
  end

  test "fix requires login" do
    flag = create :flag
    get :fix, id: flag.id
    verify_login_page
  end

  test "fix requires request owner" do
    flag = create :flag
    get :fix, {id: flag.id}, session_for(flag.donor)
    verify_wrong_login_page
  end

  # Destroy

  def destroy(flag, options)
    flag_params = options.subhash :student_name, :address, :fix_message
    params = {id: flag.id, flag: flag_params}
    current_user = options.has_key?(:current_user) ? options[:current_user] : flag.student

    assert_difference "flag.events.count", (options[:expect_events] || 1) do
      delete :destroy, params, session_for(current_user)
    end
  end

  def verify_destroy(flag, params)
    assert_redirected_to flag.request

    expected_notice = params[:expected_notice]
    expected_notice ||= if params[:role] == :fulfiller
      /notified #{flag.fulfiller} \(Free Objectivist Books volunteer\)/
    else
      /notified #{flag.donor} \(the donor\)/
    end
    assert_match expected_notice, flash[:notice], flash.inspect

    flag.reload
    assert flag.fixed?
    assert !flag.donation.flagged?
    assert_equal params[:student_name], flag.student_name
    assert_equal params[:address], flag.address
    assert_equal params[:fix_type], flag.fix_type
    assert_equal params[:fix_message], flag.fix_message

    verify_event flag, "fix", notified?: true unless params[:expect_events] == 0
  end

  test "destroy update shipping info" do
    flag = create :flag
    options = {student_name: flag.student_name, address: "123 Quantum Ln", fix_message: "", fix_type: "updated shipping info"}
    destroy flag, options
    verify_destroy flag, options
  end

  test "destroy only message" do
    flag = create :flag
    options = {student_name: flag.student_name, address: flag.address, fix_message: "No changes here", fix_type: nil}
    destroy flag, options
    verify_destroy flag, options
  end

  test "destroy flagged by fulfiller" do
    fulfillment = create :fulfillment
    fulfillment.donation.flag!
    flag = fulfillment.donation.flag

    options = {student_name: flag.student_name, address: flag.address, fix_message: "It's all good", fix_type: nil, role: :fulfiller}
    destroy flag, options
    verify_destroy flag, options
  end

  test "destroy autoflag" do
    donation = create :donation_for_request_no_address
    flag = donation.flag
    options = {student_name: flag.student_name, address: "123 Main St", fix_message: "", fix_type: "added a shipping address", expected_notice: /Thank you/}
    destroy flag, options
    verify_destroy flag, options
  end

  test "destroy requires address" do
    flag = create :flag
    destroy flag, student_name: flag.student_name, address: "", expect_events: 0
    assert_response :success
    assert_select '.field_with_errors', /We need your address/
  end

  test "destroy without change requires message" do
    flag = create :flag
    destroy flag, student_name: flag.student_name, address: flag.address, expect_events: 0
    assert_response :success
    assert_select '.field_with_errors', /enter a message/
  end

  test "destroy requires login" do
    flag = create :flag
    destroy flag, student_name: flag.student_name, address: flag.address, current_user: nil, expect_events: 0
    verify_login_page
  end

  test "destroy requires request owner" do
    flag = create :flag
    destroy flag, student_name: flag.student_name, address: flag.address, current_user: flag.donor, expect_events: 0
    verify_wrong_login_page
  end
end
