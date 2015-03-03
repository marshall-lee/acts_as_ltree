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

    def descendants(relation, path, depth=nil)
      unless depth
        relation.where(
          Arel::Nodes::LtreeIsDescendant.new(
            column,
            Arel::Nodes.build_quoted(path)
          )
        )
      else
        matching_lquery(relation, "#{path}.*")
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
