# Puppet functions!
This directory is a placeholder/demo for Puppet functions until I make
a real Puppet module

For example, cd to this directory and:

```bash
puppet apply --modulepath=. showme.pp

# $ puppet apply --modulepath=. showme.pp
# 
# Notice: Compiled catalog for jojo.example.com in environment production in 0.30 seconds
# Notice: leftovercarrots.example.com site=mars
# Notice: /Stage[main]/Main/Notify[Noodle is magic]/message: defined 'message' as 'leftovercarrots.example.com site=mars'
# Notice: orange
# Notice: /Stage[main]/Main/Notify[Noodle is parametized]/message: defined 'message' as 'orange'
# Notice: Finished catalog run in 0.17 seconds
```
