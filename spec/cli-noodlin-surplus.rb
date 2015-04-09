require_relative 'spec_helper'

describe 'Noodle' do
  it "should noodlin surplus" do
    hostname = HappyHelper::randomhostname
    # Create it
    noodlin = "create -s mars -i host -p hr -P prod #{hostname}"
    assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}
    
    # Make sure it's there
    noodle = "site= #{hostname}"
    assert_output(stdout="#{hostname} site=mars\n"){puts %x{bin/noodle #{noodle}}}

    # Surplus it
    noodlin = "surplus #{hostname}"
    assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}

    # Make sure status changed
    noodle = "status=surplus #{hostname}"
    assert_output(stdout="#{hostname}\n"){puts %x{bin/noodle #{noodle}}}
  end
end
