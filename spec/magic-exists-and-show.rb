# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it 'allow finding and showing with TERM?=' do
    post '/nodes/lolo.example.com?now', HappyHelper.node_funky_jupiter
    assert_equal 201, last_response.status

    get "/nodes/_/funky#{CGI.escape('?=')}"
    assert_equal 200, last_response.status
    assert _(last_response.body).must_include 'lolo.example.com funky=town'
  end
end
