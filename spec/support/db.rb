require 'pg'
require 'active_record'

ActiveRecord::Base.establish_connection adapter: 'postgresql',
                                        database: 'acts_as_ltree_test',
                                        min_messages: 'warning'

#ActiveRecord::Base.logger = Logger.new(STDOUT)
#ActiveRecord::Base.logger.level = Logger::DEBUG
