# frozen_string_literal: true

# I AM MONKEY #1 who gets ElasticAPM.log_ids passed to @logger.add so
# they go into ECS access log:
module EcsLogging
  class Middleware
    def call(env)
      status, headers, body = @app.call(env)
      # This leads to empty string being passed as final arg:
      # body = BodyProxy.new(body) { log(env, status, headers, ElasticAPM.log_ids) }
      # This works: ids = ElasticAPM.log_ids
      # This also works and matches ECS:
      log_ids = {}
      log_ids[:"transaction.id"] = ElasticAPM.current_transaction&.id unless ElasticAPM.current_transaction&.id.nil?
      log_ids[:"trace.id"] = ElasticAPM.current_transaction&.trace_id unless ElasticAPM.current_transaction&.trace_id.nil?
      log_ids[:"span.id"] = ElasticAPM.current_span&.id unless ElasticAPM.current_span&.id.nil?

      body = BodyProxy.new(body) { log(env, status, headers, log_ids) }
      [status, headers, body]
    end

    private

    def log(env, status, _headers, log_ids)
      req_method = env['REQUEST_METHOD']
      path = env['PATH_INFO']
      message = "#{req_method} #{path}"

      severity = status >= 500 ? Logger::ERROR : Logger::INFO

      extras = {
        client: { address: env['REMOTE_ADDR'] },
        http: { request: { method: req_method } },
        url: {
          domain: env['HTTP_HOST'],
          path: path,
          port: env['SERVER_PORT'],
          scheme: env['HTTPS'] == 'on' ? 'https' : 'http'
        }
      }.merge(log_ids)

      if (content_length = env["CONTENT_LENGTH"])
        extras[:http][:request][:'body.bytes'] = content_length
      end

      if (user_agent = env['HTTP_USER_AGENT'])
        extras[:user_agent] = { original: user_agent }
      end

      @logger.add(severity, message, **extras)
    end
  end
end

# I AM MONKEY #2 who gets the APM trace IDs into the correct ECS location:
module EcsLogging
  class Logger < ::Logger
    def add(severity, message = nil, progname = nil, include_origin: false, **extras)
      severity ||= UNKNOWN

      return true if @logdev.nil? or severity < level
      progname = @progname if progname.nil?

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = @progname
        end
      end

      if apm_agent_present_and_running? && extras.nil?
        extras[:"transaction.id"] = ElasticAPM.current_transaction&.id
        extras[:"trace.id"] = ElasticAPM.current_transaction&.trace_id
        extras[:"span.id"] = ElasticAPM.current_span&.id
      end

      @logdev.write(
        format_message(
          format_severity(severity),
          Time.now,
          progname,
          message,
          **extras
        )
      )

      true
    end
  end
end
