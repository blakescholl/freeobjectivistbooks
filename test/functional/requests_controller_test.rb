require 'test_helper'

class RequestsControllerTest < ActionController::TestCase
  # Index

  test "index" do
    user = create :donor, :with_pledge

    get :index, params, session_for(user)
    assert_response :success

    assert_select '.request', /Howard Roark/ do
      assert_select '.headline', "Howard Roark wants Atlas Shrugged"
      assert_select '.book_price', "$9.99"
      assert_select '.send_yourself', /or send it yourself/i
    end

    assert_select '.request', /Quentin Daniels/ do
      assert_select '.headline', "Quentin Daniels wants Objectivism: The Philosophy of Ayn Rand"
      assert_select '.book_price', false
      assert_select '.send_yourself', /not eligible/i
    end

    assert_select '.sidebar' do
      assert_select 'h2', "Your donations"
      assert_select 'p', "You have pledged to donate 5 books."
      assert_select 'p', /haven.+t donated any books towards this pledge yet/
      assert_select 'ul'
    end

    assert_select '.request .headline', text: "Howard Roark wants The Fountainhead", count: 0
  end

  test "index for user with previous donations" do
    user = create :donor, :with_pledge
    donation = create :donation, :sent, user: user

    get :index, params, session_for(user)
    assert_response :success

    assert_select '.sidebar p', /donated 1 book/
  end

  test "index for user with flagged donations" do
    user = create :donor, :with_pledge
    donation = create :donation_for_request_no_address, user: user

    get :index, params, session_for(user)
    assert_response :success

    assert_select '.sidebar p', /1 book flagged/
  end

  test "index for user with balance" do
    user = create :donor, balance: 20

    get :index, params, session_for(user)
    assert_response :success

    assert_select '.sidebar p', /\$20 to spend/
  end

  test "index requires login" do
    get :index
    verify_login_page
  end

  # New

  test "new" do
    get :new, params, session_for(@dagny)
    assert_response :success

    assert_select 'h1', /Get a free Objectivist book/
    assert_select "#request_book_id_#{@atlas.id}[checked=\"checked\"]"
    assert_select 'p', /No address given/
    assert_select 'a', /Add/
    assert_select 'a', /Cancel/
  end

  test "new with address" do
    get :new, params, session_for(@hank)
    assert_response :success

    assert_select 'h1', /Get a free Objectivist book/
    assert_select "#request_book_id_#{@atlas.id}[checked=\"checked\"]"
    assert_select 'p', /987 Steel Way/
    assert_select 'a', /Edit/
    assert_select 'a', /Cancel/
  end

  test "new from read" do
    get :new, params(from_read: true), session_for(@dagny)
    assert_response :success

    assert_select 'h1', /Get your next Objectivist book/
    assert_select "#request_book_id_#{@atlas.id}[checked=\"checked\"]"
    assert_select 'p', /No address given/
    assert_select 'a', /Add/
    assert_select 'a', /Skip/
  end

  test "no new" do
    get :new, params, session_for(@howard)
    assert_response :success

    assert_select 'h1', /One request at a time/
    assert_select 'p', /already have an open request for Atlas Shrugged/
    assert_select 'form', false
  end

  # Create

  def new_request(user, options = {})
    request = {
      book_id: @atlas.id,
      other_book: "",
      reason: "Heard it was great",
      user_name: user.name,
      address: user.address,
      pledge: 1
    }

    {request: request.merge(options)}
  end

  test "create" do
    assert_difference "@dagny.requests.count" do
      post :create, new_request(@dagny), session_for(@dagny)
    end

    @dagny.reload
    request = @dagny.requests.first
    assert_redirected_to request

    assert_equal @atlas, request.book
    assert_equal "Heard it was great", request.reason
    assert request.open?, "request is not open"
    assert_open_at_is_recent request
  end

  test "create with shipping info" do
    assert_difference "@dagny.requests.count" do
      post :create, new_request(@dagny, address: "123 Taggart St"), session_for(@dagny)
    end

    @dagny.reload
    request = @dagny.requests.first
    assert_redirected_to request

    assert_equal @atlas, request.book
    assert_equal "Heard it was great", request.reason
    assert_equal "123 Taggart St", request.address
    assert request.open?, "request is not open"
    assert_open_at_is_recent request
  end

  test "create with other book" do
    title = "The DIM Hypothesis"
    assert_difference "@dagny.requests.count" do
      post :create, new_request(@dagny, book_id: "", other_book: title), session_for(@dagny)
    end

    @dagny.reload
    request = @dagny.requests.first
    assert_redirected_to request

    assert_equal title, request.book.title
    assert_equal "Heard it was great", request.reason
    assert request.open?, "request is not open"
    assert_open_at_is_recent request
  end

  test "create requires reason" do
    assert_no_difference "@dagny.requests.count" do
      post :create, new_request(@dagny, reason: ""), session_for(@dagny)
    end

    assert_response :success
    assert_select 'h1', /Get/
    assert_select '.field_with_errors', /required/
  end

  test "create requires pledge" do
    assert_no_difference "@dagny.requests.count" do
      post :create, new_request(@dagny, pledge: false), session_for(@dagny)
    end

    assert_response :success
    assert_select 'h1', /Get/
    assert_select '.field_with_errors', /must pledge/
  end

  test "create requires can_request?" do
    assert_no_difference "@quentin.requests.count" do
      post :create, new_request(@quentin), session_for(@quentin)
    end

    assert_response :success
    assert_select 'h1', /One request at a time/
    assert_select 'form', false
  end

  # Show

  def verify_status(status)
    assert_select 'h2', /status: #{status}/i
  end

  test "show open request" do
    request = create :request
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    assert_select 'h1', /Student \d+ wants Book \d+/
    assert_select '.tagline', "Studying philosophy at U. of California in Anytown, USA"
    verify_status 'looking'
  end

  test "show granted" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_status 'donor found'
  end

  test "show sent" do
    donation = create :donation, status: 'sent'
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_status 'book sent'
  end

  test "show received" do
    donation = create :donation, status: 'received'
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_status 'book received'
  end

  test "show read" do
    donation = create :donation, status: 'read'
    review = create :review, user: donation.student, book: donation.book, donation: donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_status 'finished reading'
    assert_select '.review', /enjoyed it/
  end

  test "show to donor displays address" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    assert_select '.address', /\d+ Main St/
  end

  test "show to donor doesn't display address if paid" do
    donation = create :donation, :paid
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    assert_select '.address', false
  end

  test "show to fulfiller displays address" do
    fulfillment = create :fulfillment
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    assert_select '.address', /\d+ Main St/
  end

  test "show open request with missing address has no error" do
    request = create :request_no_address
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    assert_select '.message.error', false
  end

  test "show granted request with missing address has error" do
    donation = create :donation_for_request_no_address
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    assert_select '.message.error .headline', /We need your address/
    assert_select '.message.error .headline a', /Add/
  end

  test "show request flagged address has error" do
    donation = create :donation
    donation.flag!
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    assert_select '.message.error .headline', /problem with your shipping info/
    assert_select '.message.error .headline a', /Update/
  end

  test "show to donor with missing address" do
    donation = create :donation_for_request_no_address
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    assert_select '.message.error', false
    assert_select '.address', /no address/i
    assert_select '.flagged', /Student has been contacted/i
  end

  test "show to donor with flagged address" do
    donation = create :donation
    donation.flag!
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    assert_select '.message.error', false
    assert_select '.address', /\d+ Main St/i
    assert_select '.flagged', /Shipping info flagged/i
  end

  test "show to fulfiller with flagged address" do
    fulfillment = create :fulfillment
    fulfillment.donation.flag!
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    assert_select '.message.error', false
    assert_select '.address', /\d+ Main St/i
    assert_select '.flagged', /Shipping info flagged/i
  end

  test "show requires login" do
    request = create :request
    get :show, id: request.id
    verify_login_page
  end

  test "show requires request owner, donor or fulfiller" do
    request = create :request
    user = create :user
    get :show, {id: request.id}, session_for(user)
    verify_wrong_login_page
  end

  # Edit

  test "edit no donor" do
    get :edit, {id: @howard_request.id}, session_for(@howard)
    assert_response :success
    assert_select 'h1', "Your shipping info"
    assert_select 'p', text: /back at the top/, count: 0
    assert_select "form[action=\"#{request_path(@howard_request)}\"]"
    assert_select 'input[type="text"][value="Howard Roark"]#request_user_name'
    assert_select 'textarea#request_address', ""
    assert_select 'p', /you can enter this later/i
    assert_select 'textarea#event_message', false
    assert_select 'input.update[type="submit"]'
    assert_select 'a', /Cancel/
  end

  test "edit with donor" do
    get :edit, {id: @quentin_request.id}, session_for(@quentin)
    assert_response :success
    assert_select 'h1', "Your shipping info"
    assert_select 'p', text: /back at the top/, count: 0
    assert_select "form[action=\"#{request_path(@quentin_request)}\"]"
    assert_select 'input[type="text"][value="Quentin Daniels"]#request_user_name'
    assert_select 'textarea#request_address', @quentin.address
    assert_select 'p', text: /you can enter this later/i, count: 0
    assert_select 'input.update[type="submit"]'
    assert_select '.message.error', false
    assert_select 'a', /Cancel/
  end

  test "edit flagged redirects to fix" do
    flag = create :flag
    get :edit, {id: flag.request.id}, session_for(flag.student)
    assert_redirected_to fix_flag_url(flag)
  end

  test "edit requires login" do
    get :edit, id: @howard_request.id
    verify_login_page
  end

  test "edit requires request owner" do
    get :edit, {id: @howard_request.id}, session_for(@quentin)
    verify_wrong_login_page
  end

  # Update

  def update(request, options)
    request_params = options.subhash :user_name, :address
    current_user = options.has_key?(:current_user) ? options[:current_user] : request.user

    assert_difference "request.events.count", (options[:expect_events] || 1) do
      post :update, {id: request.id, request: request_params}, session_for(current_user)
    end
  end

  def verify_update(request, params)
    assert_redirected_to request
    assert_not_nil flash[:notice], flash.inspect

    request.reload
    assert_equal params[:user_name], request.user_name
    assert_equal params[:address], request.address
  end

  test "update no donor" do
    options = {user_name: "Howard Roark", address: "123 Independence St"}
    update @howard_request, options
    verify_update @howard_request, options
    verify_event @howard_request, "update", detail: "added a shipping address"
  end

  test "update requires address if granted" do
    options = {user_name: "Quentin Daniels", address: "", expect_events: 0}
    update @quentin_request, options
    assert_response :success
    assert_select '.field_with_errors', /We need your address/
  end

  test "update requires login" do
    options = {user_name: "Howard Roark", address: "123 Independence St", current_user: nil, expect_events: 0}
    update @howard_request, options
    verify_login_page
  end

  test "update requires request owner" do
    options = {user_name: "Howard Roark", address: "123 Independence St", current_user: @quentin, expect_events: 0}
    update @howard_request, options
    verify_wrong_login_page
  end

  # Cancel

  test "cancel" do
    get :cancel, {id: @hank_request.id}, session_for(@hank)
    assert_response :success
    assert_select 'h1', /Cancel/
    assert_select '.headline', /Atlas Shrugged/
    assert_select 'p', /We'll send this to your donor \(Henry Cameron\)/
    assert_select 'textarea#request_event_message', ""
    assert_select 'input[type="submit"]'
    assert_select 'a', /Don&#x27;t cancel/
  end

  test "cancel no donor" do
    get :cancel, {id: @howard_request.id}, session_for(@howard)
    assert_response :success
    assert_select 'h1', /Cancel/
    assert_select '.headline', /Atlas Shrugged/
    assert_select 'p', text: /We'll send this to your donor/, count: 0
    assert_select 'textarea#request_event_message', ""
    assert_select 'input[type="submit"]'
    assert_select 'a', /Don&#x27;t cancel/
  end

  test "cancel already-canceled request" do
    get :cancel, {id: @howard_request_canceled.id}, session_for(@howard)
    assert_redirected_to @howard_request_canceled
    assert_match /already been canceled/i, flash[:notice]
  end

  test "cancel request that can't be canceled" do
    get :cancel, {id: @quentin_request.id}, session_for(@quentin)
    assert_redirected_to @quentin_request
    assert_match /can't cancel/i, flash[:error]
  end

  test "cancel requires login" do
    get :cancel, id: @howard_request.id
    verify_login_page
  end

  test "cancel requires request owner" do
    get :cancel, {id: @howard_request.id}, session_for(@quentin)
    verify_wrong_login_page
  end

  # Destroy

  test "destroy" do
    assert_difference "@hank_request.events.count" do
      delete :destroy, {id: @hank_request.id, request: {event: {message: "Not needed"}}}, session_for(@hank)
    end
    assert_redirected_to profile_url
    assert_match /request has been canceled/i, flash[:notice]

    @hank_request.reload
    assert @hank_request.canceled?, "request not canceled"

    @hank_donation.reload
    assert @hank_donation.canceled?, "donation not canceled"

    verify_event @hank_request, "cancel_request", message: "Not needed"
  end

  test "destroy no donor" do
    assert_difference "@howard_request.events.count" do
      delete :destroy, {id: @howard_request.id, request: {event: {message: "Not needed"}}}, session_for(@howard)
    end
    assert_redirected_to profile_url
    assert_match /request has been canceled/i, flash[:notice]

    @howard_request.reload
    assert @howard_request.canceled?, "request not canceled"

    verify_event @howard_request, "cancel_request", message: "Not needed"
  end

  test "destroy already-canceled request" do
    assert_no_difference "@howard_request_canceled.events.count" do
      delete :destroy, {id: @howard_request_canceled.id, request: {event: {message: ""}}}, session_for(@howard)
    end
    assert_redirected_to profile_url
    assert_match /request has been canceled/i, flash[:notice]
  end

  test "destroy request that can't be canceled" do
    delete :destroy, {id: @quentin_request.id, request: {event: {message: ""}}}, session_for(@quentin)
    assert_redirected_to @quentin_request
    assert_match /can't cancel/i, flash[:error]

    @quentin_request.reload
    assert !@quentin_request.canceled?
  end

  test "destroy requires login" do
    delete :destroy, id: @howard_request.id
    verify_login_page
  end

  test "destroy requires request owner" do
    delete :destroy, {id: @howard_request.id}, session_for(@quentin)
    verify_wrong_login_page
  end

  # Renew form

  test "renew form" do
    request = create :request, :renewable

    get :edit, {id: request.id, renew: true}, session_for(request.user)
    assert_response :success

    assert_select 'h1', /Please confirm/
    assert_select 'p', /back at the top/
    assert_select "form[action=\"#{renew_request_path(request)}\"]"
    assert_select 'input[type="text"]#request_user_name'
    assert_select 'textarea#request_address'
    assert_select 'input.confirm[type="submit"]'
    assert_select 'a', /cancel/
  end

  test "renew form requires old request" do
    request = create :request

    get :edit, {id: request.id, renew: true}, session_for(request.user)
    assert_redirected_to request
    assert_match /created recently/, flash[:error]
  end

  test "renew form requires renewable request" do
    request = create :request, created_at: 5.weeks.ago, open_at: Time.now

    get :edit, {id: request.id, renew: true}, session_for(request.user)
    assert_redirected_to request
    assert_match /put back at the top of the list recently/, flash[:error]
  end

  test "renew form for canceled request requires can_request?" do
    request = create :request, :renewable, :canceled
    request2 = create :request, user: request.user

    get :edit, {id: request.id, renew: true}, session_for(request.user)
    assert_redirected_to request
    assert_not_nil flash[:error]
  end

  test "renew form requires open request" do
    request = create :request, :renewable
    request.grant!

    get :edit, {id: request.id, renew: true}, session_for(request.user)
    assert_redirected_to request
    assert_not_nil flash[:error]
  end

  test "renew form requires login" do
    request = create :request, :renewable

    get :edit, {id: request.id, renew: true}
    verify_login_page
  end

  test "renew form requires request owner" do
    request = create :request, :renewable
    user = create :user

    get :edit, {id: request.id, renew: true}, session_for(user)
    verify_wrong_login_page
  end

  # Renew

  def renew_params
    {user_name: "John Galt", address: "123 Rationality Way"}
  end

  test "renew" do
    request = create :request, :renewable

    put :renew, {id: request.id, request: renew_params}, session_for(request.user)
    assert_redirected_to request

    request.reload
    assert_open_at_is_recent request
    assert_equal "John Galt", request.user.name
    assert_equal "123 Rationality Way", request.user.address

    verify_event request, "renew", detail: "renewed"
  end

  test "renew of canceled request is a reopen" do
    request = create :request, :renewable, :canceled

    put :renew, {id: request.id, request: renew_params}, session_for(request.user)
    assert_redirected_to request

    request.reload
    assert request.active?
    assert_open_at_is_recent request
    assert_equal "John Galt", request.user.name
    assert_equal "123 Rationality Way", request.user.address

    verify_event request, "renew", detail: "reopened"
  end

  test "renew of recent canceled request is an uncancel" do
    request = create :request, :canceled, open_at: 1.day.ago
    open_at = request.open_at

    put :renew, {id: request.id}, session_for(request.user)
    assert_redirected_to request

    request.reload
    assert request.active?
    assert_equal open_at.to_i, request.open_at.to_i

    verify_event request, "renew", detail: "uncanceled"
  end

  test "renew is idempotent" do
    request = create :request, open_at: 1.minute.ago
    open_at = request.open_at

    put :renew, {id: request.id, request: renew_params}, session_for(request.user)
    assert_redirected_to request

    request.reload
    assert_equal open_at.to_i, request.open_at.to_i
  end

  test "renew for canceled request requires can_request?" do
    request = create :request, :renewable, :canceled
    request2 = create :request, user: request.user

    put :renew, {id: request.id}, session_for(request.user)
    assert_redirected_to request
    assert_not_nil flash[:error]

    request.reload
    assert request.canceled?
  end

  test "renew requires open request" do
    request = create :request, :renewable
    open_at = request.open_at
    request.grant!

    put :renew, {id: request.id, request: renew_params}, session_for(request.user)
    assert_redirected_to request
    assert_not_nil flash[:error]

    request.reload
    assert_equal open_at.to_i, request.open_at.to_i
  end

  test "renew requires valid shipping info" do
    request = create :request, :renewable
    open_at = request.open_at
    name = request.user.name

    put :renew, {id: request.id, request: renew_params.merge(user_name: "")}, session_for(request.user)
    assert_response :success
    assert_select 'h1', /Please confirm/
    assert_select "form[action=\"#{renew_request_path(request)}\"]"
    assert_select '.field_with_errors', /blank/
    assert_select 'input.confirm[type="submit"]'

    request.reload
    assert_equal open_at.to_i, request.open_at.to_i
    assert_equal name, request.user.name
  end

  test "renew requires login" do
    request = create :request, :renewable

    put :renew, {id: request.id, request: renew_params}
    verify_login_page
  end

  test "renew requires request owner" do
    request = create :request, :renewable
    user = create :user

    put :renew, {id: request.id, request: renew_params}, session_for(user)
    verify_wrong_login_page
  end
end
