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

      class_eval <<-INSTANCE_METHODS

        def strict_descendants
          self_and_descendants(min_depth: 1)
        end

        def children
          self_and_descendants(exact_depth: 1)
        end

        def descendants(options = {})
          self_and_descendants(options).where(
            self.class.arel_table[self.class.primary_key].not_eq(id)
            )
        end

        def self_and_descendants(options = {})
          path = self.#{column_name}
          self.class.descendants_of(path, options)
        end

        def preload_descendants(options = {})
          SubtreeCache.new(self, #{base_options}.merge(options)).proxify(self)
        end

        def depth
          self.#{column_name}.count('.')
        end

        def new_child(attributes)
          leaf_label = attributes.delete(:leaf_label)
          attributes["#{column_name}"] = "\#{path}.\#{leaf_label}"
          self.class.new(attributes)
        end

        def create_child(attributes)
          leaf_label = attributes.delete(:leaf_label)
          attributes["#{column_name}"] = "\#{path}.\#{leaf_label}"
          self.class.create(attributes)
        end

      INSTANCE_METHODS

    end
  end
end

require "acts_as_ltree/version"
require "acts_as_ltree/arel"
require "acts_as_ltree/railtie" if defined? Rails::Railtie
require "acts_as_ltree/query_builder"
require "acts_as_ltree/subtree_cache"
