require 'active_support/proxy_object'

module ActsAsLtree
  class SubtreeCache
    def initialize(root_object, options = {})
      @root_object       = root_object
      @proxy_options     = options

      proxy_options[:cache] = self
    end

    def children_for(object)
      relative_depth = object.depth - root_depth
      cache = self

      object.children.extending do
        define_method :load do
          @records = (cache.group_by_depth[object.depth + 1] || []).select do |obj|
            obj.send(cache.proxy_options[:column_name]).start_with? "#{object.path}."
          end.map do |obj|
            if !cache.max_depth || relative_depth + 1 < cache.max_depth
              Proxy.new obj, cache.proxy_options
            else
              obj
            end
          end
        end
      end
    end

    def descendants_for(object)
      descendants = object.descendants
      unless max_depth
        cache = self
        descendants.extending! do
          define_method :load do
            descendant_depths = cache.all_depths.select{ |depth| depth > object.depth }
            @records = cache.group_by_depth.values_at(*descendant_depths).flatten
          end
        end
      end
      descendants
    end

    attr_reader :root_object, :max_depth, :proxy_options

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
      def initialize(object, options = {})
        @object      = object
        @cache       = options[:cache] || SubtreeCache.new(object, options)
      end

      def respond_to_missing?(method, include_private = false)
        super || @object.respond_to?(method)
      end

      def method_missing(method, *args, &block)
        return super unless @object.respond_to?(method)
        @object.send(method, *args, &block)
      end

      def children
        @cache.children_for(@object)
      end

      def descendants
        @cache.descendants_for(@object)
      end
    end
  end
end
