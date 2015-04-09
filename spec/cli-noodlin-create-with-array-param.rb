require_relative 'spec_helper'

describe 'Noodle' do
  it "should noodlin create with array param" do
    hostname = HappyHelper::randomhostname
    # Create it
    noodlin = "create -s mars -i host -p hr -P prod -a role=db,app #{hostname}"
    assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}
    
    # Make sure it's there and that role is an array
    noodle = "role= #{hostname}"
    assert_output(stdout="#{hostname} role=app,db\n"){puts %x{bin/noodle #{noodle}}}
  end
end
