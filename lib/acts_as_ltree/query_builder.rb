module ActsAsLtree
  class QueryBuilder
    def initialize(column)
      @column = column
    end

    def matching_lquery(query)
      Arel::Nodes::LtreeMatchLquery.new(
        column,
        Arel::Nodes.build_quoted(query)
      )
    end

    def matching_ltxtquery(query)
      Arel::Nodes::LtreeMatchLtxtquery.new(
        column,
        Arel::Nodes.build_quoted(query)
      )
    end

    class DescendantsParams
      attr_reader :min_depth, :max_depth

      def initialize(options)
        @min_depth = options[:min_depth]
        @max_depth = options[:max_depth]
        @exact_depth = options[:exact_depth]
        validate!
      end

      def validate!
        validate_instances!
        validate_usage!
      end

      def validate_instances!
        [:min_depth, :max_depth, :exact_depth].each do |name|
          value = send name
          if value && !value.is_a?(Integer)
            fail ArgumentError, "#{name} must be an Integer"
          end
        end
      end

      def validate_usage!
        not_ok = exact_depth && (min_depth || max_depth)
        fail ArgumentError, <<-ERROR.strip! if not_ok
exact_depth cannot be used with min_depth or max_depth
ERROR
      end

      def depth_specified?
        min_depth || max_depth || exact_depth
      end

      def exact_depth?
        @exact_depth || (min_depth && min_depth == max_depth)
      end

      def exact_depth
        @exact_depth || (exact_depth? && min_depth)
      end
    end

    def descendants(path, options = {})
      params = DescendantsParams.new(options)
      if params.depth_specified?
        if params.exact_depth?
          exact_depth_descendants(path, params.exact_depth)
        else
          range_depth_descendants(path, params.min_depth, params.max_depth)
        end
      else
        all_descendants(path)
      end
    end

    def exact_depth_descendants(path, exact_depth)
      query = "#{path}.*{#{exact_depth}}"
      matching_lquery query
    end

    def range_depth_descendants(path, min_depth, max_depth)
      query = "#{path}.*{#{min_depth || nil},#{max_depth || nil}}"
      matching_lquery(query)
    end

    def all_descendants(path)
      Arel::Nodes::LtreeIsDescendant.new(
        column,
        Arel::Nodes.build_quoted(path)
      )
    end

    def ancestors(path)
      Arel::Nodes::LtreeIsAncestor.new(
        column,
        Arel::Nodes.build_quoted(path)
      )
    end

    private

    attr_reader :column
  end
end
