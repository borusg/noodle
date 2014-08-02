require 'sinatra/base'

class Noodle < Sinatra::Base
    get '/help' do
        "Noodle helps!\n"
    end
end

