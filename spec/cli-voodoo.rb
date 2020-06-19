require_relative 'spec_helper'

describe 'Noodle' do
  it 'voodoo work' do
    # Create project=hr
    hostname_hr = HappyHelper.randomhostname
    noodlin = "create -s mars -i host -p hr -P prod -a voodoo=yes #{hostname_hr}"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Create project=warehouse
    hostname_warehouse = HappyHelper.randomhostname
    noodlin = "create -s mars -i host -p warehouse -P prod -a voodoo=yes #{hostname_warehouse}"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # refresh bareword_hash (and options but bareword_hash is what matters for voodoo)
    get '/nodes/_/voodoo=yes?refresh'

    # Make sure noodle hr only returns the first one
    noodle = 'hr voodoo=yes'
    assert_output("#{hostname_hr}\n") { puts `bin/noodle #{noodle}` }
  end
end
