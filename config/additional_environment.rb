config.gem 'memcached-northscale', :lib => 'memcached'
require 'memcached'
config.cache_store = :mem_cache_store, ::Memcached::Rails.new
