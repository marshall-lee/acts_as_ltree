require "active_record"
require "active_support/concern"

module ActsAsLtree
  extend ActiveSupport::Concern

  module ClassMethods
    def acts_as_ltree(opts = {})
      column_name = opts[:on] || :path

      instance_eval <<-CLASS_METHODS
        def ltree_query_builder
          @query_builder ||= ActsAsLtree::QueryBuilder.new(arel_table[:#{column_name}])
        end

        def descendants_of(path, options={})
          where ltree_query_builder.descendants(path, options)
        end

        def ancestors_of(path)
          where ltree_query_builder.ancestors(path)
        end

        def matching_lquery(query)
          where ltree_query_builder.matching_lquery(query)
        end

        def matching_ltxtquery(query)
          where ltree_query_builder.matching_ltxtquery(query)
        end
      CLASS_METHODS

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
          SubtreeCache.new(self, {column_name: :#{column_name}}.merge(options)).proxify(self)
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
