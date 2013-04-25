require 'test_helper'

class Admin::TestimonialsControllerTest < ActionController::TestCase
  def setup
    super
    @testimonial = testimonials :testimonial_1
    @new_testimonial = {title: "Title", type: 'student', text: "Some text here", attribution: "John Galt, Patrick Henry U."}
  end

  # Index

  test "index" do
    get :index, params, session_for(users :admin)
    assert_response :success
    assert_select 'a', /add new/i
    assert_select '.testimonial', count: Testimonial.count
  end

  # New

  test "new" do
    get :new, params, session_for(users :admin)
    assert_response :success
    assert_select 'input[type="submit"]'
  end

  test "new from review" do
    get :new, {source_type: 'Review', source_id: @quentin_review.id}, session_for(users :admin)
    assert_response :success
    assert_select 'input#testimonial_source_type[value="Review"]'
    assert_select 'input#testimonial_source_id[value="' + @quentin_review.id.to_s + '"]'
    assert_select 'input#testimonial_title[value="On *Atlas Shrugged*"]'
    assert_select 'input[type="submit"]'
  end

  test "new from thank-you" do
    event = events :quentin_thanks_hugh
    get :new, {source_type: 'Event', source_id: event.id}, session_for(users :admin)
    assert_response :success
    assert_select 'input#testimonial_source_type[value="Event"]'
    assert_select 'input#testimonial_source_id[value="' + event.id.to_s + '"]'
    assert_select 'input#testimonial_title[value="A thank-you"]'
    assert_select 'input[type="submit"]'
  end

  # Create

  test "create" do
    assert_difference "Testimonial.count" do
      post :create, {testimonial: @new_testimonial}, session_for(users :admin)
    end
    assert_redirected_to admin_testimonials_url
    assert_match /Created/, flash[:notice]
  end

  test "create from source" do
    assert_difference "Testimonial.count" do
      post :create, {testimonial: @new_testimonial.merge(source_type: 'Review', source_id: @quentin_review.id)}, session_for(users :admin)
    end
    assert_redirected_to admin_testimonials_url
    assert_match /Created/, flash[:notice]

    testimonial = Testimonial.last
    assert_equal @quentin_review, testimonial.source
  end

  # Edit

  test "edit" do
    get :edit, {id: @testimonial.id}, session_for(users :admin)
    assert_response :success
    assert_select 'input#testimonial_title[value="Work of genius"]'
    assert_select 'input[type="submit"]'
  end

  # Update

  test "update" do
    put :update, {id: @testimonial.id, testimonial: {title: "New Title", text: "New text", attribution: "New attribution"}}, session_for(users :admin)
    assert_redirected_to admin_testimonials_url
    assert_match /Updated/, flash[:notice]

    @testimonial.reload
    assert_equal "New Title", @testimonial.title
  end

  # Destroy

  test "destroy" do
    assert_difference "Testimonial.count", -1 do
      delete :destroy, {id: @testimonial.id}, session_for(users :admin)
    end
    assert_redirected_to admin_testimonials_url
    assert !Testimonial.exists?(@testimonial)
  end
end
