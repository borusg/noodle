notify{'Noodle is parametized':
  message => noodleparam('plakistan','color')
}

# This only prints the first element of the array returned by
# noodlemagic but you get the idea
notify{'Noodle is magic':
  message => noodlemagic('site=')
}
