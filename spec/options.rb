require_relative 'spec_helper'

describe 'Noodle' do
  it "should respond to OPTIONS for /nodes/blah" do
    options '/nodes/qoqo.example.com'
    assert_equal last_response.status,200
    assert _(last_response.headers['Allow']).must_include 'DELETE, GET, OPTIONS, PATCH, POST, PUT'
  end
end

