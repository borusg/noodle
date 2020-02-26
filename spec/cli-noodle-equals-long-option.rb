require_relative 'spec_helper'

describe 'Noodle' do
  it "should --find-and-show TERM" do
    hostname = HappyHelper::randomhostname
    noodlin = "create -s mars -i host -p hr -P prod #{hostname}"
    assert_output("\n"){puts %x{bin/noodlin #{noodlin}}}

    noodle = "--find-and-show site #{hostname}"
    assert_output("#{hostname} site=mars\n"){puts %x{bin/noodle #{noodle}}}
  end
end
