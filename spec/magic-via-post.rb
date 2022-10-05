# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'allow searching via POST' do
    post '/nodes/jupjup.example.com?now', HappyHelper.node_jupiter
    assert_equal 201, last_response.status

    post '/nodes/_/', ['jupjup', 'prodlevel='].to_json
    assert last_response.body.must_include 'jupjup.example.com prodlevel=dev'
  end
end
