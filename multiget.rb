require 'sinatra'
require 'json/ext'
require 'rack/cache'
require './model'
use ActiveRecord::ConnectionAdapters::ConnectionManagement
use Rack::Cache, :metastore => 'memcached://localhost:11211/meta', :entitystore => 'file:/mnt/tmp'
set :static_cache_control, [:public, :max_age => 1000000]
disable :protection

get('/stats') {
  expires 1000000, :public
  input_ids = params["ids"]
  input_order = params["order"]
  pass unless input_ids =~ /^\d+(,\d+)*$/ && input_order =~ /^[2345]$/
  ids = params["ids"].split(',').map(&:to_i)
  order = params["order"].to_i
  ngrams = Prefetch(ids, order)
  Multiget(ids, order, ngrams)
}
