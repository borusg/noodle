# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'Make magic finds bellybutton.example.com but not bellybutton-2.example.com' do
    post '/nodes/bellybutton.example.com?now', HappyHelper.node_neptune
    assert_equal 201, last_response.status
    post '/nodes/bellybutton-2.example.com?now', HappyHelper.node_neptune
    assert_equal 201, last_response.status

    get '/nodes/_/bellybutton.example.com%20prodlevel='
    assert_equal 200, last_response.status
    assert_equal "bellybutton.example.com prodlevel=dev\n", last_response.body
  end
end
