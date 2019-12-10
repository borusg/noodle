# Quick Start

## Installing and running by hand

- Remember to install and start
  [Elasticsearch](http://www.elasticsearch.org/overview/elkdownloads/)
- `git clone https://github.com/borusg/noodle.git`
- `cd noodle`
- `bundle install --path vendor/bundle`
- Or perhaps `bundle exec rake test 2>&1 | grep -v
  '(elasticsearch-persistence|virtus).*: warning:'` because some of
  the Gems cause warnings (as of 9/2017)
- Run tests: `bundle exec rake test`
- Or just run a single test: `bundle exec rake test
  TEST=spec/create-then-get.rb`
- Start app: `bundle exec rackup`
