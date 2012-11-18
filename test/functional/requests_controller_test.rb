require 'test_helper'

class RequestsControllerTest < ActionController::TestCase
  # Index

  test "index" do
    get :index, params, session_for(@hugh)
    assert_response :success

    assert_select '.request .headline', "Howard Roark wants Atlas Shrugged"
    assert_select '.request .headline', "Quentin Daniels wants Objectivism: The Philosophy of Ayn Rand"
    assert_select '.request .headline', "Francisco d'Anconia wants We the Living"

    assert_select '.sidebar' do
      assert_select 'h2', "Your donations"
      assert_select 'p', "You have pledged to donate 5 books."
      assert_select 'p', "You previously donated 3 books."
      assert_select 'ul'
    end

    assert_select '.request .headline', text: "Howard Roark wants The Fountainhead", count: 0
  end

  test "index for send-money donor" do
    get :index, params, session_for(@cameron)
    assert_response :success

    assert_select '.request .headline', "Howard Roark wants Atlas Shrugged"

    assert_select '.sidebar' do
      assert_select 'h2', "Your donations"
      assert_select 'p', "You have pledged to donate 1 book."
      assert_select 'p', /You have promised/
      assert_select 'ul'
    end

    assert_select '.request .headline', text: "Quentin Daniels wants Objectivism: The Philosophy of Ayn Rand", count: 0
    assert_select '.request .headline', text: "Francisco d'Anconia wants We the Living", count: 0
    assert_select '.request .headline', text: "Howard Roark wants The Fountainhead", count: 0
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

  def verify_thank_link(present = true)
    verify_link 'thank', present
  end

  def verify_add_address_link(present = true)
    verify_link 'add your address', present
  end

  def verify_update_shipping_link(present = true)
    verify_link 'update shipping', present
  end

  def verify_flag_link(present = true)
    verify_link 'flag', present
  end

  def verify_back_link(present = true)
    verify_link 'back', present
  end

  def verify_sent_button(present = true, options = {})
    assert_select '.sidebar form', present
    verify_link 'Amazon', (present && options[:amazon_link].to_bool)
  end

  def verify_status(status)
    assert_select 'h2', /status: #{status}/i
  end

  def verify_address_link(which)
    verify_add_address_link (which == :add)
    verify_update_shipping_link (which == :update)
  end

  def verify_cancel_request_link(present = true)
    verify_link 'cancel this request', present
  end

  def verify_not_received_link(present = true)
    verify_link 'report book not received', present
  end

  def verify_cancel_donation_link(present = true)
    verify_link 'cancel this donation', present
  end

  def verify_donor_links(status, options = {})
    verify_back_link
    verify_flag_link (status == :not_sent)
    verify_sent_button (status.in? [:not_sent, :flagged]), options
    verify_cancel_donation_link (status.in? [:not_sent, :sent, :flagged])

    verify_thank_link false
    verify_add_address_link false
    verify_update_shipping_link false
    verify_cancel_request_link false
    verify_not_received_link false
  end

  def verify_no_donor_links
    verify_back_link false
    verify_flag_link false
    verify_sent_button false
    verify_cancel_donation_link false
  end

  test "show no donor" do
    get :show, {id: @howard_request.id}, session_for(@howard)
    assert_response :success
    assert_select 'h1', "Howard Roark wants Atlas Shrugged"
    assert_select '.tagline', "Studying architecture at Stanton Institute of Technology in New York, NY"
    assert_select '.address', /no address/i
    verify_status 'looking'
    verify_thank_link false
    verify_address_link :add
    verify_cancel_request_link
    verify_not_received_link false
    verify_no_donor_links
  end

  test "show to donor" do
    get :show, {id: @quentin_request.id}, session_for(@hugh)
    assert_response :success
    assert_select 'h1', "Quentin Daniels wants The Virtue of Selfishness"
    assert_select '.tagline', "Studying physics at MIT in Boston, MA"
    assert_select '.address', /123 Main St/
    verify_status 'book sent'
    verify_donor_links :sent
  end

  test "show to donor unsent" do
    get :show, {id: @quentin_request_unsent.id}, session_for(@hugh)
    assert_response :success
    assert_select 'h1', "Quentin Daniels wants The Fountainhead"
    assert_select '.tagline', "Studying physics at MIT in Boston, MA"
    assert_select '.address', /123 Main St/
    verify_status 'donor found'
    verify_donor_links :not_sent
  end

  test "show to donor received" do
    get :show, {id: @hank_request_received.id}, session_for(@cameron)
    assert_response :success
    assert_select 'h1', "Hank Rearden wants The Fountainhead"
    verify_status 'book received'
    verify_donor_links :received
  end

  test "show unsent" do
    get :show, {id: @quentin_request_unsent.id}, session_for(@quentin)
    assert_response :success
    assert_select 'h1', "Quentin Daniels wants The Fountainhead"
    assert_select '.tagline', "Studying physics at MIT in Boston, MA"
    assert_select '.address', /123 Main St/
    verify_status 'donor found'
    assert_select '.sidebar' do
      assert_select 'h2', /Update/
      assert_select 'p', /Let Hugh Akston know when you have received\s+The Fountainhead/
    end
    verify_not_received_link
    verify_thank_link
    verify_address_link :update
    verify_cancel_request_link
    verify_no_donor_links
  end

  test "show sent" do
    get :show, {id: @quentin_request.id}, session_for(@quentin)
    assert_response :success
    assert_select 'h1', "Quentin Daniels wants The Virtue of Selfishness"
    assert_select '.tagline', "Studying physics at MIT in Boston, MA"
    assert_select '.address', /123 Main St/
    verify_status 'book sent'
    assert_select '.sidebar' do
      assert_select 'h2', /Update/
      assert_select 'p', /Let Hugh Akston know when you have received\s+The Virtue of Selfishness/
    end
    verify_thank_link
    verify_address_link :none
    verify_cancel_request_link false
    verify_not_received_link false
    verify_no_donor_links
  end

  test "show received" do
    get :show, {id: @hank_request_received.id}, session_for(@hank)
    assert_response :success
    assert_select 'h1', "Hank Rearden wants The Fountainhead"
    assert_select '.tagline', "Studying manufacturing at University of Pittsburgh in Philadelphia, PA"
    assert_select '.address', /987 Steel Way/
    verify_status 'book received'
    assert_select '.sidebar' do
      assert_select 'h2', /Update/
      assert_select 'p', /Let Henry Cameron know when you have finished reading\s+The Fountainhead/
    end
    verify_thank_link
    verify_address_link :none
    verify_cancel_request_link false
    verify_not_received_link false
    verify_no_donor_links
  end

  test "show read" do
    get :show, {id: @quentin_request_read.id}, session_for(@quentin)
    assert_response :success
    assert_select 'h1', "Quentin Daniels wants Atlas Shrugged"
    assert_select '.tagline', "Studying physics at MIT in Boston, MA"
    verify_status 'finished reading'
    assert_select '.review', /It was great/
    assert_select 'p', text: /Let .* know/, count: 0
    verify_thank_link false
    verify_address_link :none
    verify_cancel_request_link false
    verify_not_received_link false
    verify_no_donor_links
  end

  test "show to student with missing address" do
    get :show, {id: @dagny_request.id}, session_for(@dagny)
    assert_response :success
    assert_select '.message.error .headline', /We need your address/
    assert_select '.message.error .headline a', /Add/
    assert_select 'h1', "Dagny wants Capitalism: The Unknown Ideal"
    verify_status 'donor found'
    verify_thank_link false
    verify_address_link :add
    verify_cancel_request_link
    verify_not_received_link false
    verify_no_donor_links
  end

  test "show to student with flagged address" do
    get :show, {id: @hank_request.id}, session_for(@hank)
    assert_response :success
    assert_select '.message.error .headline', /problem with your shipping info/
    assert_select '.message.error .headline a', /Update/
    assert_select 'h1', "Hank Rearden wants Atlas Shrugged"
    verify_thank_link true
    verify_address_link :update
    verify_cancel_request_link
    verify_not_received_link false
    verify_no_donor_links
  end

  test "show to donor with missing address" do
    get :show, {id: @dagny_request.id}, session_for(@hugh)
    assert_response :success
    assert_select '.message.error', false
    assert_select 'h1', "Dagny wants Capitalism: The Unknown Ideal"
    assert_select '.address', /no address/i
    assert_select '.flagged', /Student has been contacted/i
    verify_donor_links :flagged
  end

  test "show to donor with flagged address" do
    get :show, {id: @hank_request.id}, session_for(@cameron)
    assert_response :success
    assert_select '.message.error', false
    assert_select 'h1', "Hank Rearden wants Atlas Shrugged"
    assert_select '.address', /987 Steel Way/i
    assert_select '.flagged', /Shipping info flagged/i
    verify_donor_links :flagged, amazon_link: true
  end

  test "show canceled" do
    get :show, {id: @howard_request_canceled.id}, session_for(@howard)
    assert_response :success
    assert_select 'h1', "Howard Roark wants The Fountainhead"
    verify_thank_link false
    verify_address_link :none
    verify_cancel_request_link false
    verify_not_received_link false
    verify_no_donor_links
  end

  test "show flagged and canceled" do
    get :show, {id: @dagny_request_canceled.id}, session_for(@dagny)
    assert_response :success
    assert_select 'h1', "Dagny wants Atlas Shrugged"
    verify_thank_link false
    verify_address_link :none
    verify_cancel_request_link false
    verify_not_received_link false
    verify_no_donor_links
  end

  test "show requires login" do
    get :show, id: @howard_request.id
    verify_login_page
  end

  test "show requires request owner or donor" do
    get :show, {id: @howard_request.id}, session_for(@quentin)
    verify_wrong_login_page
  end

  # Edit

  test "edit no donor" do
    get :edit, {id: @howard_request.id}, session_for(@howard)
    assert_response :success
    assert_select 'input[type="text"][value="Howard Roark"]#request_user_name'
    assert_select 'textarea#request_address', ""
    assert_select 'p', /you can enter this later/i
    assert_select 'textarea#event_message', false
    assert_select 'input[type="submit"]'
  end

  test "edit with donor" do
    get :edit, {id: @quentin_request.id}, session_for(@quentin)
    assert_response :success
    assert_select 'input[type="text"][value="Quentin Daniels"]#request_user_name'
    assert_select 'textarea#request_address', @quentin.address
    assert_select 'p', text: /you can enter this later/i, count: 0
    assert_select 'input[type="submit"]'
    assert_select '.message.error', false
  end

  test "edit flagged redirects to fix" do
    get :edit, {id: @hank_request.id}, session_for(@hank)
    assert_redirected_to fix_donation_flag_url(@hank_donation)
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
    verify_event @howard_request, "update", detail: "added a shipping address", notified?: false
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
    assert_select 'a', /Don't cancel/
  end

  test "cancel no donor" do
    get :cancel, {id: @howard_request.id}, session_for(@howard)
    assert_response :success
    assert_select 'h1', /Cancel/
    assert_select '.headline', /Atlas Shrugged/
    assert_select 'p', text: /We'll send this to your donor/, count: 0
    assert_select 'textarea#request_event_message', ""
    assert_select 'input[type="submit"]'
    assert_select 'a', /Don't cancel/
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

    verify_event @hank_request, "cancel_request", message: "Not needed", notified?: true
  end

  test "destroy no donor" do
    assert_difference "@howard_request.events.count" do
      delete :destroy, {id: @howard_request.id, request: {event: {message: "Not needed"}}}, session_for(@howard)
    end
    assert_redirected_to profile_url
    assert_match /request has been canceled/i, flash[:notice]

    @howard_request.reload
    assert @howard_request.canceled?, "request not canceled"

    verify_event @howard_request, "cancel_request", message: "Not needed", notified?: false
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
end
