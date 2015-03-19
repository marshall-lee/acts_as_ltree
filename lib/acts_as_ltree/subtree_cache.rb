require 'active_support/proxy_object'

module ActsAsLtree
  class SubtreeCache
    def initialize(root_object, options = {})
      @root_object = root_object
      @options     = options
    end

    def children_for(object)
      children = with_depth_equal(object.depth + 1).select do |obj|
        obj[column_name].start_with? "#{object.path}."
      end
      children.map! { |obj| proxify(obj) }
    end

    def descendants_for(object)
      descendant_depths = all_depths.select { |depth| depth > object.depth }
      group_by_depth.values_at(*descendant_depths).flatten
    end

    def all_descendants?
      !max_depth
    end

    def proxify(object)
      relative_depth = object.depth - root_depth
      if all_descendants? || relative_depth <= max_depth
        Proxy.new object, self
      else
        object
      end
    end

    private

    attr_reader :root_object, :options

    def column_name
      options[:column_name]
    end

    def max_depth
      options[:max_depth]
    end

    def with_depth_equal(depth)
      group_by_depth[depth] || []
    end

    def root_depth
      root_object.depth
    end

    def group_by_depth
      @by_depth ||= root_object.descendants.group_by(&:depth)
    end

    def all_depths
      group_by_depth.keys
    end

    class Proxy < ActiveSupport::ProxyObject
      def initialize(object, cache)
        @object      = object
        @cache       = cache
      end

      def respond_to_missing?(method, include_private = false)
        super || @object.respond_to?(method)
      end

      def method_missing(method, *args, &block)
        return super unless @object.respond_to?(method)
        @object.send(method, *args, &block)
      end

      def children
        cache, object = @cache, @object
        @object.children.extending! do
          define_method :load do
            @records = cache.children_for(object)
          end
        end
      end

      def descendants
        descendants = @object.descendants
        if @cache.all_descendants?
          cache, object = @cache, @object
          descendants.extending! do
            define_method :load do
              @records = cache.descendants_for(object)
            end
          end
        end
        descendants
      end
    end
  end
end
