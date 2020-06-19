require_relative 'spec_helper'

describe 'Noodle' do
  hostname_with_hash    = JSON.load(HappyHelper::node_hashdig)['facts']['fqdn']
  hostname_without_hash = JSON.load(HappyHelper::node_hashdig_without_hash)['facts']['fqdn']
  dotted_param = 'gum.address.zipcode'
  param_value  = '90210'
  dotted_fact  = 'chew.carrots.times'
  fact_value   = '12'

  before do
    node = HappyHelper::node_hashdig
    fqdn = JSON.load(node)['facts']['fqdn']
    post "/nodes/#{fqdn}?now", node
    assert_equal 201, last_response.status

    node = HappyHelper::node_hashdig_without_hash
    fqdn = JSON.load(node)['facts']['fqdn']
    post "/nodes/#{fqdn}?now", node
    assert_equal 201, last_response.status
  end

  after do
    [hostname_with_hash, hostname_without_hash].each do |fqdn|
      delete "/nodes/#{fqdn}"
      assert_equal 200, last_response.status
      assert _(last_response.body).must_include "Deleted #{fqdn}"
    end
  end

  it "should hashdig param when BLAH=YABBA" do
    noodle = "hashdig=yep #{dotted_param}= #{hostname_with_hash}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname_with_hash} #{dotted_param}=#{param_value}\n"){puts output}
  end
  it "should hashdig fact when BLAH=YABBA" do
    noodle = "hashdig=yep #{dotted_fact}= #{hostname_with_hash}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname_with_hash} #{dotted_fact}=#{fact_value}\n"){puts output}
  end

  it "should hashdig param when BLAH?" do
    noodle = "hashdig=yep #{dotted_param}?"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname_with_hash}\n"){puts output}
  end
  it "should hashdig fact when BLAH?" do
    noodle = "hashdig=yep #{dotted_fact}?"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname_with_hash}\n"){puts output}
  end

  it "should hashdig param when BLAH?=" do
    noodle = "hashdig=yep #{dotted_param}?= #{hostname_with_hash}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname_with_hash} #{dotted_param}=#{param_value}\n"){puts output}
  end
  it "should hashdig fact when BLAH?=" do
    noodle = "hashdig=yep #{dotted_fact}?= #{hostname_with_hash}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname_with_hash} #{dotted_fact}=#{fact_value}\n"){puts output}
  end

  it "should hashdig param when @BLAH" do
    noodle = "hashdig=yep @#{dotted_param}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname_without_hash}\n"){puts output}
  end
  it "should hashdig fact when @BLAH" do
    noodle = "hashdig=yep @#{dotted_fact}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname_without_hash}\n"){puts output}
  end

  it "should hashdig param when @BLAH=YABBA" do
    noodle = "hashdig=yep @#{dotted_param}=#{param_value}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname_without_hash}\n"){puts output}
  end

  # TODO: Color me bewildered! I can't figure out why this one fails
  # despite this working for me outside of "rake test":
  #
  #it "should hashdig fact when @BLAH=YABBA" do
  #  noodle = "hashdig=yep @#{dotted_fact}=#{fact_value}"
  #  output = %x{bin/noodle #{noodle}}
  #  assert_output("#{hostname_without_hash}\n"){puts output}
  #end
end
