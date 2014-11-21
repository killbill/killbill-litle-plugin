module Killbill #:nodoc:
  module Litle #:nodoc:
    class LitleTransaction < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Transaction

      self.table_name = 'litle_transactions'

      belongs_to :litle_response

    end
  end
end
