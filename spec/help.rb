# Cribbed from http://recipes.sinatrarb.com/p/testing/rspec

require File.expand_path '../spec_helper.rb', __FILE__

describe "Noodle" do
  it "should allow getting help" do
    get '/help'
    expect last_response.ok?
    expect last_response.body == 'Noodle Helps!'
  end
end

