require 'active_support/proxy_object'

module ActsAsLtree
  class SubtreeCache
    def initialize(object, options={})
      @object      = object
      @options     = options
      options[:depth] ||= 0
    end

    def children
      @children ||=
        begin
          (cache[path_depth+1] || {}).select do |obj|
            obj.send(column_name).start_with? "#{path}."
          end.map do |obj|
            if cacheable_next?
              Proxy.new obj, options.merge(depth: depth + 1)
            else
              Proxy.new obj, options.merge(cache: nil, depth: 0, max_depth: 1)
            end
          end
        end
    end

    def ancestors
      unless max_depth
        cache.slice(*cache.keys.select! { |d| d > path_depth }).values.flatten!
      else
        SubtreeCache.new(object, options.merge(cache: nil, max_depth: nil)).ancestors
      end
    end

    private
    attr_reader :object, :options

    def model
      object.class
    end

    def path
      object.send column_name
    end

    def path_depth
      @path_depth ||= path.count('.')
    end

    [
      :column_name,
      :depth,
      :max_depth
    ].each do |name|
      class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{name}
          options[:#{name}]
        end
      RUBY
    end

    def cacheable_next?
      !max_depth || depth + 1 < max_depth
    end

    def cache
      options[:cache] ||=
        begin
          depth_pattern = if max_depth
                            "*{#{max_depth}}"
                          else
                            "*"
                          end
          relation = model.where(
            Arel::Nodes::LtreeMatchLquery.new(
              model.arel_table[column_name],
              Arel::Nodes.build_quoted("#{path}.#{depth_pattern}")
            )
          )
          relation.to_a
            .group_by do |obj|
              obj.send(column_name).count('.')
            end
        end
    end

    class Proxy < ActiveSupport::ProxyObject
      def initialize(object, options={})
        @object      = object
        @subtree     = SubtreeCache.new object, options
      end

      def respond_to_missing?(method, include_private = false)
        super || @object.respond_to?(method)
      end

      def method_missing(method, *args, &block)
        return super unless @object.respond_to?(method)
        @object.send(method, *args, &block)
      end

      def children
        @subtree.children
      end

      def ancestors
        @subtree.ancestors
      end
    end
  end
end
