if ENV['RACK_ENV'] == 'production'
  stdout_redirect('/var/log/noodle/error.log', '/var/log/noodle/access.log', true)
end
