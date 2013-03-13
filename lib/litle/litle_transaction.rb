require 'active_record'

class LitleTransaction < ActiveRecord::Base
  attr_accessible :api_call, :kb_payment_id, :litle_txn_id
end
