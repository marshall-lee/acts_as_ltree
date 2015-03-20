require 'arel'

module Arel
  module Nodes
    class LtreeBinary < Arel::Nodes::Binary
      alias :operand1 :left
      alias :operand2 :right
    end

    class LtreeMatchLquery < LtreeBinary
      def operator; :'~' end
    end

    class LtreeMatchLtxtquery < LtreeBinary
      def operator; :'@' end
    end

    class LtreeIsAncestor < LtreeBinary
      def operator; :'@>' end
    end

    class LtreeIsDescendant < LtreeBinary
      def operator; :'<@' end
    end

    class LtreeLCA < Arel::Nodes::NamedFunction
      def initialize expr, aliaz = nil
        super :lca, expr, aliaz
      end
    end
  end

  module Visitors
    class DepthFirst
      alias :visit_Arel_Nodes_LtreeBinary :binary
    end

    class ToSql
      def visit_Arel_Nodes_LtreeBinary o, collector
        collector = visit o.left, collector
        collector << " #{o.operator} "
        visit o.right, collector
      end
    end
  end
end
