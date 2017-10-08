require_relative 'client'

# TODO: Bootstrapping options into ilk=option, emptyness, etc etc is
# far too finicky. Rework this whole thing

# TODO: Is a separate class for this premature optimization?
# TODO: Bubble up to target_ilk=default if not defined in the requested target_ilk?

# ilk=option target_ilk=host uniqueness=fqdn
# ilk=option target_ilk=sslcert uniqueness=fqdn
# ilk=option target_ilk=samlcert uniqueness=fqdn,component_type (component_type would be shibboleth|asimba)
class Noodle::Option
  def self.get(target_ilk='default')
    # See above notes about making this better. Until then:

    # *Always* merge with built-in options, regardless of
    # *target_ilk. This way we are certain no required options are
    # *left out. It's too easy to leave something out and which makes
    # *bootstrapping your own ilk=option entry cause errors in
    # *node.rb.

    # Define built-in options:
    builtin_options = {
      'uniqueness_params' => %w(ilk),
      'required_params'   => %w{ilk prodlevel project site status},
      'default_ilk'       => 'host',
      'default_status'    => 'enabled',
      'bareword_terms'    => %w{prodlevel project site},
      'limits'            => {
        'gum'               => 'hash',
        'ilk'               => %w{host option esx ucschassis ucsfi},
        'prodlevel'         => %w{dev preprod prod test},
        'project'           => %w{hr financials lms noodle registration warehouse},
        'role'              => 'array',
        'site'              => %w{jupiter mars moon neptune pluto uranus},
        'stack'             => 'array',
        'status'            => %w{disabled enabled future surplus},
        # Not in alphabetical order because they match the ones above outside the limits hash
        'bareword_terms'    => 'array',
        'limits'            => 'hash',
        'required_parms'    => 'array',
        'uniqueness_params' => 'array',
      }
    }
    # First, set default_options to built-in options
    default_options = builtin_options
    # Then let any defaults from the Noodle database override the
    # built-in options:
    default_options_from_db = Noodle::Search.new(Noodle::Node).equals('ilk','option').equals('target_ilk','default').go.results.first
    default_options.merge(default_options_from_db['params']) unless default_options_from_db.nil?
    # We're done if target_ilk is 'default'
    return default_options if target_ilk == 'default'

    # Otherwise, Find target_ilk options just like above:
    target_options = builtin_options
    # Let target_ilk options from Noodle database override built-ins:
    target_options_from_db = Noodle::Search.new(Noodle::Node).equals('ilk','option').equals('target_ilk',target_ilk).go.results.first
    target_options.merge(target_options_from_db['params']) unless target_options_from_db.nil?
    return target_options
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
