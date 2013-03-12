require 'active_record'

class LitlePaymentMethod < ActiveRecord::Base
  attr_accessible :kb_account_id, :kb_payment_method_id, :litle_token
end
