require_relative 'spec_helper'

describe 'Noodle' do
  it "should noodlin param role+=db" do
    hostname = HappyHelper::randomhostname

    noodlin = "create -s mars -i host -p hr -P prod -a role=db #{hostname}"
    assert_output("\n"){puts %x{bin/noodlin #{noodlin}}}

    noodlin = "param role+=app,web #{hostname}"
    assert_output("\n"){puts %x{bin/noodlin #{noodlin}}}

    # Make sure role param is present and correct
    noodle = "role= #{hostname}"
    assert_output("#{hostname} role=app,db,web\n"){puts %x{bin/noodle #{noodle}}}
  end
end
