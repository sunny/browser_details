# -*- encoding: utf-8 -*-

require "browser_details/version"
require "useragent"

# Public: Middleware for logging the browser details of each request.
#
class BrowserDetails

  # Set up the log_message method.
  if defined?(Hatchet)
    # If Hatchet is defined include it and define a method for its logger.
    include Hatchet

    def log_message(env, message)
      log.info(message)
    end
  elsif defined?(Rails)
    # If Rails is defined define a method for its logger.
    def log_message(env, message)
      Rails.logger.info(message)
    end
  else
    # Otherwise check if the env includes a logger and if so log to that.
    def log_message(env, message)
      if env['rack.logger']
        env['rack.logger'].info(message)
      end
    end
  end

  # Make whatever log_message method that was defined private.
  private :log_message

  # Public: Creates a new instance.
  #
  # app - The application this middleware is wrapping.
  #
  def initialize(app)
    @app = app
  end

  # Public: Log the browser details if possible and then forward the request on
  # to the wrapped application.
  #
  # env - The environment of the request.
  #
  # Returns the result generated by the wrapped application.
  #
  def call(env)
    request = Rack::Request.new(env)
    message = self.class.message(request)

    # Log a message if any details were gathered.
    unless message.empty?
      log_message(env, message)
    end

    # Delegate to the application we are wrapping.
    @app.call(env)
  end

  # Public: Creates a new message.
  #
  # request - The request.
  #
  # Returns a string with the message we want to show.
  #
  def self.message(request)
    message = []

    # Add the user agent details to the message if present.
    if request.user_agent
      agent = UserAgent.parse(request.user_agent)

      agent_details = [agent.browser]
      agent_details << 'Mobile' if agent.mobile?
      agent_details << agent.version
      agent_details << "(#{agent.platform}, #{agent.os})"

      message << agent_details.join(' ')
    end

    # Parameter unchanged
    if request['utf8'] && request['utf8'] == '✓'
      message << 'JS disabled'

    # Parameter changed or Ajax
    elsif request['utf8'] or request.xhr?
      message << 'JS enabled'
    end

    message.join(', ')
  end
end

# Require the Railtie if Rails is present.
require 'browser_details/railtie' if defined?(Rails)
