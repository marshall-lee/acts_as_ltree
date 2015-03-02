
module ActsAsLtree
  class Railtie < Rails::Railtie
    ActiveSupport.on_load :active_record do
      ActiveRecord::Base.send(:include, ActsAsLtree)
    end
  end
end
