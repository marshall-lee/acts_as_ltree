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
        # TODO: call matching_lquery with "#{path}.*{n,m}" query (or even "#{path}.*{n} if exact_depth is given)
        #       raise ArgumentError if one of *_depth options is not Integer (if present)
        #       raise ArgumentError if exact_depth is present but min_depth and max_depth are present
        #       if min_depth == max_depth then perform *{n} query instead of *{n,n}
        raise NotImplementedError
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
