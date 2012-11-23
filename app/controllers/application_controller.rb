# Thrown when a session with no current user tries something that requires login.
class UnauthorizedException < StandardError; end

# Thrown when a session wiwth a current user tries something that is not allowed for that user.
class ForbiddenException < StandardError; end

# Thrown when a blocked user tries to access any page or action.
class BlockedUserException < StandardError; end

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :find_current_user, :reject_blocked_users, :store_referral, :parse_params, :load_models, :check_user

  def initialize
    super
    # Introspects the relevant model for this controller. E.g., if this is the RequestsController,
    # the model is Request and the ivar is @request. This is used by load_models.
    @model_class_name = self.class.name.split("::").last.sub(/Controller$/,"").singularize
    @model_class = @model_class_name.constantize if Kernel.const_defined?(@model_class_name)
    @model_ivar_name = "@#{@model_class_name.underscore}"
  end

  #--
  # Filters
  #++

  # Loads the current user from the session. Automatically invoked before all requests.
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

  # Sets the current user in the session.
  def set_current_user(user)
    logger.info "setting current user: " + (@current_user ? "#{@current_user.name} (#{@current_user.id})" : "none")
    reset_session
    session[:user_id] = user && user.id
    @current_user = user
  end

  def reject_blocked_users
    raise BlockedUserException if @current_user && @current_user.blocked?
  end

  # Creates a Referral object to track this referral/landing; stores it in the session so it can be
  # associated with any downstream signup.
  def store_referral
    return unless params[:utm_source] || params[:utm_medium]
    referral = Referral.create source: params[:utm_source], medium: params[:utm_medium], landing_url: request.url,
      referring_url: request.env["HTTP_REFERER"]
    session[:referral_id] = referral.id
  end

  # By convention, extracts values from params, parses them if needed, and stores them in ivars, e.g.:
  #
  #     @public = params[:public].to_bool
  #
  # Default implementation is empty; subclasses can override. Called as a before_filter on all requests.
  def parse_params
  end

  # Loads the main model, if any, from the id parameter, along with some other models commonly
  # used by controllers. May be overridden by subclasses to load additional models, but subclass
  # implementations should call super.
  def load_models
    instance_variable_set @model_ivar_name, @model_class.find(params[:id]) if @model_class && params[:id]
    @request = Request.find params[:request_id] if params[:request_id]
    @donation = Donation.find params[:donation_id] if params[:donation_id]
  end

  # Invokes render_unauthorized if there is no current logged-in user.
  # Optional before_filter that subclasses can use.
  def require_login
    raise UnauthorizedException if !@current_user
  end

  def require_user(*users)
    require_login
    users = users.flatten.compact
    raise ForbiddenException if !@current_user.in?(users)
  end
  private :require_user

  # Uses HTTP digest authentication to validate admin credentials.
  def require_admin
    authenticate_or_request_with_http_digest("Admin") do |username|
      Rails.application.config.admin_password_hash
    end
  end

  # Specifies who can access this page. Subclasses can override this to return a user or a list of
  # users, in order to restrict access to those users. The render_forbidden handler will be invoked
  # for all other users.
  #
  # If nil or empty list is returned, *all* users are allowed. (This is the default.)
  def allowed_users
  end

  # Invokes render_forbidden if there are allowed_users and the current user is not one of them.
  # Automatically invoked as a before_filter on all requests.
  def check_user
    users = Array(allowed_users)
    require_user users unless users.empty?
  end

  #--
  # Helpers
  #++

  # Saves a set of models. Validates *all* models before saving *any* of them.
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
  private :log_errors

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

  #--
  # Error handling
  #++

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception, with: :render_error
    rescue_from ActionController::RoutingError, with: :render_not_found
    rescue_from ActionController::UnknownController, with: :render_not_found
    rescue_from ActionController::UnknownAction, with: :render_not_found
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  end

  rescue_from UnauthorizedException, with: :render_unauthorized
  rescue_from ForbiddenException, with: :render_forbidden
  rescue_from BlockedUserException, with: :render_blocked_user

  # Renders an HTTP 401 Unauthorized response for HTML or JSON.
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

  # Renders an HTTP 403 Forbidden response for HTML or JSON.
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

  # Renders a response for a blocked user.
  def render_blocked_user
    respond_to do |format|
      format.html do
        @destination = request.url
        render template: "errors/blocked", status: 403
      end
      format.json do
        render json: {message: 'Something is wrong with your account.'}, status: 403
      end
    end
  end

  # Renders an HTTP 404 Not Found response for HTML or JSON.
  def render_not_found
    respond_to do |format|
      format.html { render template: "errors/404", status: 404 }
      format.json { render json: {message: 'Sorry, we hit an unexpected error. Try reloading the page.'}, status: 404 }
    end
  end

  # Renders an HTTP 500 Internal Server Error response for HTML or JSON. Invoked on all uncaught exceptions.
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
