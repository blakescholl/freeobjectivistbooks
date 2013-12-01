class Admin::AccountingController < AdminController
  def index
    @metrics = Metrics::Accounting.new
  end
end
