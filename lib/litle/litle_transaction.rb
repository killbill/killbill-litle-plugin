require 'active_record'

module Killbill::Litle
  class LitleTransaction < ActiveRecord::Base
    belongs_to :litle_response
    attr_accessible :amount_in_cents, :api_call, :kb_payment_id, :litle_txn_id

    def self.from_kb_payment_id(kb_payment_id)
      litle_transactions = find_all_by_api_call_and_kb_payment_id(:charge, kb_payment_id)
      raise "Unable to find Litle transaction id for payment #{kb_payment_id}" if litle_transactions.empty?
      raise "Killbill payment mapping to multiple Litle transactions for payment #{kb_payment_id}" if litle_transactions.size > 1
      litle_transactions[0]
    end
  end
end