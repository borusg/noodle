require 'hashie'
require_relative 'client'

# TODO: Bootstrapping options into ilk=option, emptyness, etc etc is
# far too finicky. Rework this whole thing

# TODO: Is a separate class for this premature optimization?
# TODO: Bubble up to target_ilk=default if not defined in the requested target_ilk?

# ilk=option target_ilk=host uniqueness=fqdn
# ilk=option target_ilk=sslcert uniqueness=fqdn
# ilk=option target_ilk=samlcert uniqueness=fqdn,component_type (component_type would be shibboleth|asimba)
class Noodle::Option
  # This contains all ilk=options entries with target_ilk as the key
  @@bareword_hash = {}
  # Define built-in options:
  @@builtin_options = {
    'uniqueness_params' => %w(ilk),
    'required_params'   => %w{created_by ilk last_updated_by prodlevel project site status},
    'default_ilk'       => 'host',
    'default_status'    => 'enabled',
    'bareword_terms'    => %w{prodlevel project site},
    'limits'            => {
      'gum'               => 'hash',
      'ilk'               => %w{host option esx ucschassis ucsfi},
      'prodlevel'         => %w{dev preprod prod test},
      'project'           => %w{hr financials lms noodle registration warehouse},
      'role'              => 'array',
      'site'              => %w{jupiter mars moon neptune pluto saturn uranus venus},
      'stack'             => 'array',
      'status'            => %w{disabled enabled future surplus},
      # Not in alphabetical order because they match the ones above outside the limits hash
      'bareword_terms'    => 'array',
      'limits'            => 'hash',
      'required_parms'    => 'array',
      'uniqueness_params' => 'array',
    }
  }
  @@options = Hash.new{|k,v| k[v] = Hash.new}

  # Update the @@options and @@bareword_hash class variable caches.
  #
  # TODO: See corresponding comment in controller. This part might stay but the job isn't complete or pretty.
  def self.refresh
    ## First, update @@options
    #
    # See above notes about making this better. Until then:
    #
    # *Always* merge with built-in options, regardless of
    # target_ilk. This way we are certain no required options are
    # left out. It's too easy to leave something out and which makes
    # bootstrapping your own ilk=option entry cause errors in
    # node.rb.

    # Start out the default options with built-in options:
    @@options['default'] = Hashie::Mash.new(@@builtin_options) # TODO: Does this need DeepDup::deep_dup? Probably not because Hashie?

    # Find all ilk=option and loop
    Noodle::Search.new(Noodle::NodeRepository.repository).equals('ilk','option').go.results.each do |option_hash|
      # NOTE: This is the only time we should reference .params! This is because the options are all Noodle *params* of the ilk=option entry
      options = option_hash.params

      # Skip if target_ilk is nil
      next if options['target_ilk'].nil?

      # If the target ilk is default, merge with the default options:
      if options['target_ilk'] = 'default'
        @@options['default'].merge!(Hashie::Mash.new(options))
      else
        @@options[option_hash['target_ilk']] = options
      end
    end
    #
    ##

    ## Next, update @@bareword_hash
    #
    # Make a hash of barewordvalue => paramname for use in magic
    # For example:
    # {
    #   'mars'       => 'site'
    #   'jupiter     => 'site'
    #   'hr'         => 'project'
    #   'financials' => 'project'
    # }
    # Convoluted?  Maybe but makes magic easier
    @@bareword_hash = {}
    Noodle::Option.option('default','bareword_terms').each do |term|
      Noodle::Search.new(Noodle::NodeRepository.repository).param_values(term: term).each do |value|
        @@bareword_hash[value] = term
      end
    end
    #
    ##
  end

  def self.get(target_ilk=nil)
    target_ilk = 'default' if target_ilk.nil? or target_ilk.empty?

    # We're done if target_ilk is 'default'
    return @@options['default'] if target_ilk == 'default'

    # Also return default options if options for target_ilk don't exist:
    return @@options['default'] if @@options['target_ilk'].nil?

    # Otherwise, start with default options and then let target_ilk options override by merging:
    default_options = Hashie::Mash.new(@@options['default'])
    target_options = Hashie::Mash.new(@@options['target'])
    return default_options.merge(target_options)
  end

  def self.option(ilk,option)
    r = self.get(ilk)[option]
    return self.emptyness(ilk,option) if r.nil?
    return r
  end

  # TODO: need .empty? because who knows if caller wants string or array, etc
  def self.limit(ilk,thing)
    limits = self.get(ilk)['limits']
    return [] if limits.nil?
    limit = limits[thing]
    return [] if limit.nil?
    return limit
  end

  def self.emptyness(ilk,option)
    return [] if self.limit(ilk,option) == 'array'
    return {} if self.limit(ilk,option) == 'hash'
    return ''
  end
end
