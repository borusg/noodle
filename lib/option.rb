require 'elasticsearch/persistence/model'
require 'hashie'

class Option
    include Elasticsearch::Persistence::Model

    attribute :allowed_statuses, Array
    attribute :allowed_ilks,     Array

    # TODO: Better explanation and maybe something better than "voodoo"
    #
    # bareword_terms specifies a List of terms (fact or param names)
    # for which Voodoo Expansion works.
    #
    # Voodoo Expansion lets you specify a *value* as a bareword and have it
    # mean the same thing as term=value.  The value must be one of the possible
    # values for one of the terms in the bareword_terms array.
    #
    # For example, let's say you have nodes with various values for
    # the site param:
    #
    # site=moon
    # site=jupiter
    # site=pluto
    # site=saturn
    #
    # AND, 'site' is in the bareword_terms array.
    #
    # Then this noodle query:
    #
    # noodle moon
    #
    # acts as if you had typed this:
    #
    # noodle site=moon
    #
    # Yes it's perilous but I bet it works for me most of the time.  And I'm very lazy.
    attribute :bareword_terms,   Array  

    # limits specifies per-param limits on the values or type of
    # the param's possible values.  This does not affect facts.
    #
    # For example:
    #
    # limits = {site: %qw(moon mars jupiter)}
    #
    # says the site params can only be 'moon', 'mars' or 'jupiter'
    #
    # And this:
    #
    # limits = {role: Array}
    #
    # says that the role param must be an array.
    attribute :limits,           Hashie::Mash, mapping: { type: 'object' }, default: {}
end

