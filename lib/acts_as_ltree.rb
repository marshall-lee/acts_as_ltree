require "active_record"
require "active_support/concern"

module ActsAsLtree
  extend ActiveSupport::Concern

  module ClassMethods
    def acts_as_ltree(opts = {})
      column_name = opts[:on] || :path
      query_builder = QueryBuilder.new(arel_table[column_name])
      base_options = {
        column_name: column_name
      }

      define_singleton_method :descendants_of do |path, options = {}|
        where query_builder.descendants(path, options)
      end

      define_singleton_method :ancestors_of do |path|
        where query_builder.ancestors(path)
      end

      define_singleton_method :matching_lquery do |query|
        where query_builder.matching_lquery(query)
      end

      define_singleton_method :matching_ltxtquery do |query|
        where query_builder.matching_ltxtquery(query)
      end

      define_method :children do
        self_and_descendants(exact_depth: 1)
      end

      define_method :descendants do |options = {}|
        self_and_descendants(options).where(
          self.class.arel_table[self.class.primary_key].not_eq(id)
          )
      end

      define_method :self_and_descendants do |options = {}|
        path = self[column_name]
        self.class.descendants_of(path, options)
      end

      define_method :strict_descendants do
        self_and_descendants(min_depth: 1)
      end

      define_method :preload_descendants do |options = {}|
        SubtreeCache.new(self, base_options.merge(options)).proxify(self)
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

      define_method :depth do
        self[column_name].count('.')
      end
    end
  end
end

require "acts_as_ltree/version"
require "acts_as_ltree/arel"
require "acts_as_ltree/railtie" if defined? Rails::Railtie
require "acts_as_ltree/query_builder"
require "acts_as_ltree/subtree_cache"
