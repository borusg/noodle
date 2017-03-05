require_relative 'spec_helper'

describe 'Noodle' do
  it "should noodlin create" do
    hostname = HappyHelper::randomhostname
    # Create it
    noodlin = "create -s mars -i host -p hr -P prod #{hostname}"
    assert_output("\n"){puts %x{bin/noodlin #{noodlin}}}

    # Make sure it's there
    noodle = "site= #{hostname}"
    assert_output("#{hostname} site=mars\n"){puts %x{bin/noodle #{noodle}}}
  end
end
