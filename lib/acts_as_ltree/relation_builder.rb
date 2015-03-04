module ActsAsLtree
  class RelationBuilder
    def initialize(model, column_name)
      @model = model
      @column_name = column_name
    end

    def matching_lquery(relation, query)
      relation.where(
        Arel::Nodes::LtreeMatchLquery.new(
          column,
          Arel::Nodes.build_quoted(query)
        )
      )
    end

    def matching_ltxtquery(relation, query)
      relation.where(
        Arel::Nodes::LtreeMatchLtxtquery.new(
          column,
          Arel::Nodes.build_quoted(query)
        )
      )
    end

    def descendants(relation, path, options={})
      min_depth, max_depth, exact_depth = options.values_at :min_depth, :max_depth, :exact_depth
      unless min_depth || max_depth || exact_depth
        relation.where(
          Arel::Nodes::LtreeIsDescendant.new(
            column,
            Arel::Nodes.build_quoted(path)
          )
        )
      else
        raise ArgumentError, "min_depth must be an Integer" if min_depth && !min_depth.is_a?(Integer)
        raise ArgumentError, "max_depth must be an Integer" if max_depth && !max_depth.is_a?(Integer)
        raise ArgumentError, "exact_depth must be an Integer" if exact_depth && !exact_depth.is_a?(Integer)
        raise ArgumentError, "exact_depth cannot be used with min_depth or max_depth" if exact_depth && (min_depth || max_depth)

        if (!min_depth.nil? && min_depth.eql?(max_depth))
          exact_depth = min_depth
        end

        if exact_depth
          matching_lquery(relation, "#{path}.*{#{exact_depth}}")
        elsif min_depth
          if max_depth
            matching_lquery(relation, "#{path}.*{#{min_depth},#{max_depth}}")
          else
            matching_lquery(relation, "#{path}.*{#{min_depth},}")
          end
        elsif max_depth
          matching_lquery(relation, "#{path}.*{,#{max_depth}}")
        end
      end
    end

    def ancestors(relation, path)
      relation.where(
        Arel::Nodes::LtreeIsAncestor.new(
          column,
          Arel::Nodes.build_quoted(path)
        )
      )
    end

    private
      attr_reader :model, :column_name

      def column
        @column ||= model.arel_table[column_name]
      end
  end
end
