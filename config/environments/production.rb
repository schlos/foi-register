FoiRegister::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Take admin assets from the admin host
  admin_prefix = MySociety::Config::get("ADMIN_PREFIX", "/admin")
  if admin_prefix =~ %r(^https?://)
    config.action_controller.asset_host = Proc.new do |*args|
      # Args are source, request - but sometimes no request is available
      # and we are called with one argument. Since we want to work with
      # Ruby 1.8 we cannot use a default value for the parameter here,
      # so we decode the args ourselves.
      raise ArgumentError if args.empty? || args.size > 2
      source, request = args

      if request.nil?
        is_admin = (ENV["SCRIPT_URI"] =~ %r(/admin/)) # XXXX is this ever true?
      else
        is_admin = !request.params[:is_admin].nil?
      end

      is_admin ? admin_prefix : nil

    end
  end

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( modernizr-2.5.3.min.js ba-throttle-debounce.js admin.css )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  config.middleware.use ExceptionNotifier,
    :email_prefix => "[ERROR] ",
    :sender_address => %{"FOI register errors" <#{MySociety::Config.get("EXCEPTION_NOTIFICATIONS_FROM")}>},
    :exception_recipients => MySociety::Config.get("EXCEPTION_NOTIFICATIONS_TO")

end
