class Admin::RequestsController < AdminController
  def index
    @metrics = Metrics.new

    @requests = case params[:type]
    when 'not_granted'
      Request.not_granted.reorder(:created_at)
    when 'needs_donor_action'
      Donation.needs_donor_action.reorder('donations.created_at').map {|d| d.request}
    when 'needs_fulfillment'
      Donation.needs_fulfillment.reorder(:updated_at).map {|d| d.request}
    when 'needs_sending_by_volunteer'
      Donation.fulfilled.needs_sending.reorder('donations.created_at').map {|d| d.request}
    when 'in_transit'
      Donation.in_transit.reorder(:status_updated_at).map {|d| d.request}
    when 'reading'
      Donation.reading.reorder(:status_updated_at).map {|d| d.request}
    else
      limit_and_offset Request
    end
  end
end
