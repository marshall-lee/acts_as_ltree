require "active_record"
require "active_support/concern"

module ActsAsLtree
  extend ActiveSupport::Concern

  module ClassMethods
    def acts_as_ltree(opts={})
      column_name = opts[:on] || :path
      base_options = {
        column_name: column_name
      }

      define_method :children do
        SubtreeCache::Proxy.new(self, base_options.merge(max_depth: 1)).children
      end

      define_method :descendants do
        SubtreeCache::Proxy.new(self, base_options).descendants
      end

      define_method :preload_descendants do |options|
        options = options.slice(:max_depth)
        Subtree::Proxy.new(self, base_options.merge(options))
      end
    end
  end
end

require "acts_as_ltree/version"
require "acts_as_ltree/arel"
require "acts_as_ltree/railtie" if defined? Rails::Railtie
require "acts_as_ltree/subtree_cache"
