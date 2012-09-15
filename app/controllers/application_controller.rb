class UnauthorizedException < StandardError; end
class ForbiddenException < StandardError; end

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :find_current_user, :store_referral, :parse_params, :load_models, :check_user

  def initialize
    super
    @model_class_name = self.class.name.split("::").last.sub(/Controller$/,"").singularize
    @model_class = @model_class_name.constantize if Kernel.const_defined?(@model_class_name)
    @model_ivar_name = "@#{@model_class_name.underscore}"
  end

  # Filters

  def find_current_user
    if session[:user_id]
      @current_user = User.find_by_id session[:user_id]
      if !@current_user
        logger.warn "couldn't find current user #{session[:user_id]}, clearing session"
        reset_session
      end
    end
    logger.info "current user: " + (@current_user ? "#{@current_user.name} (#{@current_user.id})" : "none")
  end

  def set_current_user(user)
    logger.info "setting current user: " + (@current_user ? "#{@current_user.name} (#{@current_user.id})" : "none")
    reset_session
    session[:user_id] = user && user.id
    @current_user = user
  end

  # Creates a Referral object to track this referral/landing; stores it in the
  # session so it can be associated with any downstream signup.
  def store_referral
    return unless params[:utm_source] || params[:utm_medium]
    referral = Referral.create source: params[:utm_source], medium: params[:utm_medium], landing_url: request.url,
      referring_url: request.env["HTTP_REFERER"]
    session[:referral_id] = referral.id
  end

  def parse_params
  end

  def load_models
    instance_variable_set @model_ivar_name, @model_class.find(params[:id]) if @model_class && params[:id]
    @request = Request.find params[:request_id] if params[:request_id]
    @donation = Donation.find params[:donation_id] if params[:donation_id]
  end

  def require_login
    raise UnauthorizedException if !@current_user
  end

  def require_user(*users)
    require_login
    users = users.flatten.compact
    raise ForbiddenException if !@current_user.in?(users)
  end

  def allowed_users
  end

  def check_user
    users = Array(allowed_users)
    require_user users unless users.empty?
  end

  # Helpers

  def save(*models)
    models = models.flatten.compact
    valid = models.all? {|m| m.valid?}
    log_errors models unless valid
    models.each {|m| m.save} if valid
  end

  def log_errors(*models)
    models.flatten.compact.each do |model|
      logger.warn "#{model.class} errors: #{model.errors.messages}" if model.invalid?
    end
  end

  def limit_and_offset(relation, default_limit = 100)
    offset = params[:offset]
    limit = params[:limit] || default_limit

    @total = relation.count

    relation = relation.limit limit.to_i if limit
    relation = relation.offset offset.to_i if offset

    @all = relation.all
    @start = offset.to_i
    @end = @start + @all.size

    @all
  end

  # Error handling

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception, with: :render_error
    rescue_from ActionController::RoutingError, with: :render_not_found
    rescue_from ActionController::UnknownController, with: :render_not_found
    rescue_from ActionController::UnknownAction, with: :render_not_found
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  end

  rescue_from UnauthorizedException, with: :render_unauthorized
  rescue_from ForbiddenException, with: :render_forbidden

  def render_unauthorized
    respond_to do |format|
      format.html do
        logger.info "no current user, rendering login page"
        @destination = request.url
        render "sessions/new", status: 401
      end
      format.json do
        render json: {message: 'Sorry, something went wrong. Try logging in again.'}, status: 401
      end
    end
  end

  def render_forbidden
    respond_to do |format|
      format.html do
        @destination = request.url
        render template: "errors/403", status: 403
      end
      format.json do
        render json: {message: 'Sorry, something went wrong. Try logging in again.'}, status: 403
      end
    end
  end

  def render_not_found
    respond_to do |format|
      format.html { render template: "errors/404", status: 404 }
      format.json { render json: {message: 'Sorry, we hit an unexpected error. Try reloading the page.'}, status: 404 }
    end
  end

  def render_error(exception)
    trace = exception.backtrace.map {|frame| "    #{frame}"}.join("\n")
    logger.error "Caught exception #{exception.class}: #{exception.message}\n#{trace}"
    ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver

    respond_to do |format|
      format.html { render template: "errors/500", status: 500 }
      format.json { render json: {message: 'Sorry, we hit an unexpected error.'}, status: 500 }
    end
  end
end
