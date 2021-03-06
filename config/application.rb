require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module FreeBooks
  class Application < Rails::Application
    require 'extensions'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    config.active_record.observers = :balance_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Pacific Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Disabled to try to fix a bug with ActiveAdmin as per
    # https://devcenter.heroku.com/articles/rails3x-asset-pipeline-cedar#troubleshooting
    config.assets.initialize_on_precompile = false

    # Avoid i18n deprecation warning:
    # http://stackoverflow.com/questions/20361428/rails-i18n-validation-deprecation-warning
    I18n.enforce_available_locales = true

    config.email_recipient_override = nil

    # A default value is needed here in all environments; the real value only really matters in prod,
    # where it is overridden from an environment variable.
    config.mailgun_domain = "freeobjectivistbooks.mailgun.org"

    config.aws_access_key = ENV['AWS_ACCESS_KEY'] || "test-access-key"
    config.aws_secret_key = ENV['AWS_SECRET_KEY'] || "test-secret-key"
    config.amazon_associates_tag = ENV['AMAZON_ASSOCIATES_TAG']
    config.payments_live = false

    config.after_initialize do |app|
      I18n.reload!
    end
  end
end
