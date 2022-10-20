# Um, force workers to 0 for gitlab.com CI?
#
# GitLab CI gave this error but I can't tell what is trying to give the
# -w argument to Puma:
#
# "Puma caught this error: option '-w' needs a parameter (Optimist::CommandlineError)"
workers 0 if ENV['RACK_ENV'] == 'test'

if ENV['RACK_ENV'] == 'production'
  stdout_redirect('/var/log/noodle/access.log', '/var/log/noodle/error.log', true)
  log_requests
  set_remote_address header: 'X-Forwarded-For'
end
