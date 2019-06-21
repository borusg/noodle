require_relative 'option'
require 'hashie'
require 'optimist'
require 'active_model'
require 'active_model/validations'

class Noodle::Node
  class NodeUniqueValidator < ActiveModel::Validator
    # Make sure new node is, or existing node remains, unique.
    #
    # NOTE: There is a race condition. Fix later! The race condition
    # can be triggered when simultaneous node creates or param updates
    # are made. This is a rare situation (at least for us) so
    # postponing the fix seems OK.
    #
    # There is a race condition because the uniqueness check does
    # *not* insert anything into the backend store (Elasticsearch). So
    # two simultaneous uniqueness checks can decide it's OK to insert
    # identical nodes. Both uniqueness checks can succeed. After the
    # uniqueness checks, the nodes are added to Elasticsearch.
    def validate(record)
      # TODO: Don't get options every single time
      # Get default options
      record.errors.add :base, 'Gack! Ilk and name are always required params but none specified' if record.params['ilk'].nil? or record.name.nil?
      record.errors.add :base, 'Nope! Node is not unique' unless unique?(record,Noodle::Option.option(record.params['ilk'],'uniqueness_params'))
    end

    private
    def unique?(record,uniqueness_params)
      # name is always part of uniqueness
      search = Noodle::Search.new(Noodle::NodeRepository.repository).match_names_exact(record['name'])
      # Add uniqueness_params to search
      uniqueness_params.each do |param|
        return false if record.params[param].nil?
        search.equals(param,record.params[param])
      end
      # Search!
      r = search.go.results

      # Remove record itself from the results to handle cases where
      # record is getting *updated*
      r.delete_if{|node| node.id == record.id}

      # It's unique if no results remain
      r.empty?
    end
  end
end

class Noodle::Node
  include ActiveModel::Model
  include ActiveModel::Validations

  ATTRIBUTES = [:name,
                :id,
                :_id,
                :facts,
                :params]
  attr_accessor(*ATTRIBUTES)
  attr_reader :attributes

  # TODO: Intentionally skipping :fqdn
  def initialize(attrs={})
    name   = attrs[:name]                     unless attrs[:name].nil?
    facts  = Hashie::Mash.new(attrs[:facts])  unless attrs[:facts].nil?
    params = Hashie::Mash.new(attrs[:params]) unless attrs[:params].nil?
  end

  # Validate node uniqueness (by default ilk+name must be unique
  validates_with Noodle::Node::NodeUniqueValidator

  validates_each :params do |record, attr, value|
    # Check for required params
    Noodle::Option.option(record.params['ilk'],'required_params').each do |param|
      record.errors.add attr, "#{param} must be provided but is not." if value[param].nil?
    end

    record.errors.add attr, "nil value not allowed." if value.nil?
    record.errors.add attr, "Empty value not allowed." if value.empty?

    # Check per-param liits
    Noodle::Option.option(record.params['ilk'],'limits').each do |param,limit|
      case limit.class.to_s
      when 'Array'
        record.errors.add attr, "#{param} is not one of these: #{limit.join(',')}.  It is #{value[param]}." unless
          limit.include?(value[param])
      when 'String'
        record.errors.add attr, "#{param} is not a(n) #{limit}" unless
          value[param].nil? or value[param].class.to_s.downcase == limit
      end
    end
  end

  def to_puppet
    r = {}
    # TODO: Get class list from node/options
    r['classes']    = ['baseclass']
    r['parameters'] = @params
    r.to_yaml.strip
  end

  def full
    r = []
    r << "Name:   " + @name
    r << "Params: " ; r << @params.map {|term,value| "  #{term}=#{value}"}
    r << "Facts:  " ; r << @facts.map  {|term,value| "  #{term}=#{value}"}
    r.join("\n")
  end

  # If node has errors, return hash containing errors and node.
  # If no errors and ! args[:silent_if_none], return node
  # Otherwise return node
  def errors?(args={:silent_if_none => false})
    unless self.valid?
      errors = self.errors.messages.values.flatten.join("\n") + "\n"
      return {errors: errors, node: self}
    else
      return args[:silent_if_none] ? '' : self
    end
  end

  def self.all_names
    body = self.all.results.collect{|hit| hit.name}.sort.join("\n")
    [body, 200]
  end
end
