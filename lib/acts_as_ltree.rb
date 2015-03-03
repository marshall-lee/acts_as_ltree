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
      relation_builder = RelationBuilder.new(self, column_name)

      define_singleton_method :descendants_of do |path, options={}|
        relation_builder.descendants(self, path, options)
      end

      define_singleton_method :ancestors_of do |path|
        relation_builder.ancestors(self, path)
      end

      define_singleton_method :matching_lquery do |query|
        relation_builder.matching_lquery(self, query)
      end

      define_singleton_method :matching_ltxtquery do |query|
        relation_builder.matching_ltxtquery(self, query)
      end

      define_method :children do
        path = send(column_name)
        self.class.descendants_of(path, exact_depth: 1)
      end

      define_method :descendants do
        path = send(column_name)
        self.class.descendants_of(path, min_depth: 1)
      end

      define_method :preload_descendants do |options|
        options = options.slice(:max_depth)
        SubtreeCache::Proxy.new(self, base_options.merge(options))
      end

      define_method :new_child do |attributes|
        leaf_label = attributes.delete(:leaf_label)
        attributes[column_name] = "#{path}.#{leaf_label}"
        self.class.new(attributes)
      end

      define_method :create_child do |attributes|
        leaf_label = attributes.delete(:leaf_label)
        attributes[column_name] = "#{path}.#{leaf_label}"
        self.class.create(attributes)
      end
    end
  end
end

require "acts_as_ltree/version"
require "acts_as_ltree/arel"
require "acts_as_ltree/railtie" if defined? Rails::Railtie
require "acts_as_ltree/relation_builder"
require "acts_as_ltree/subtree_cache"
