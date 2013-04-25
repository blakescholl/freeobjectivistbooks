require 'test_helper'

class Admin::CampaignTargetsControllerTest < ActionController::TestCase
  test "index" do
    get :index, params, session_for(users :admin)
    assert_response :success
    assert_select 'h1', "Campaign targets"
    assert_select 'td', "CMU Objectivist Club"
  end

  test "new" do
    get :new, params, session_for(users :admin)
    assert_response :success
    assert_select 'h1', "Load targets"
    assert_select 'textarea'
    assert_select 'input[type="submit"]'
  end

  test "create" do
    hashes = [{name: "Chicago Objectivist Club", email: "objectivists@chicago.edu", group: "Objectivist Clubs"}]
    post :create, {targets_json: ActiveSupport::JSON.encode(hashes)}, session_for(users :admin)
    assert_redirected_to action: :index
    assert_not_nil CampaignTarget.find_by_email("objectivists@chicago.edu")
  end

  test "destroy" do
    target = campaign_targets :cmuoc
    delete :destroy, {id: target.id}, session_for(users :admin)
    assert_redirected_to action: :index
    assert !CampaignTarget.exists?(target)
  end
end
