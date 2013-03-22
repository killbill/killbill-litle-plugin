require 'active_record'

ActiveRecord::Schema.define(:version => 20130311153635) do
  create_table "litle_payment_methods", :force => true do |t|
    t.string   "kb_account_id",          :null => false
    t.string   "kb_payment_method_id"    # NULL before Killbill knows about it
    t.string   "litle_token",            :null => false
    t.boolean  "is_deleted",             :null => false, :default => false
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "litle_transactions", :force => true do |t|
    t.integer  "litle_response_id", :null => false
    t.string   "api_call",          :null => false
    t.string   "kb_payment_id",     :null => false
    t.string   "litle_txn_id",      :null => false
    t.integer  "amount_in_cents",   :null => false
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "litle_responses", :force => true do |t|
    t.string   "api_call",        :null => false
    t.string   "kb_payment_id"
    t.string   "message"
    t.string   "authorization"
    t.boolean  "fraud_review"
    t.boolean  "test"
    t.string   "params_litleonelineresponse_message"
    t.string   "params_litleonelineresponse_response"
    t.string   "params_litleonelineresponse_version"
    t.string   "params_litleonelineresponse_xmlns"
    t.string   "params_litleonelineresponse_saleresponse_customer_id"
    t.string   "params_litleonelineresponse_saleresponse_id"
    t.string   "params_litleonelineresponse_saleresponse_report_group"
    t.string   "params_litleonelineresponse_saleresponse_litle_txn_id"
    t.string   "params_litleonelineresponse_saleresponse_order_id"
    t.string   "params_litleonelineresponse_saleresponse_response"
    t.string   "params_litleonelineresponse_saleresponse_response_time"
    t.string   "params_litleonelineresponse_saleresponse_message"
    t.string   "params_litleonelineresponse_saleresponse_auth_code"
    t.string   "avs_result_code"
    t.string   "avs_result_message"
    t.string   "avs_result_street_match"
    t.string   "avs_result_postal_match"
    t.string   "cvv_result_code"
    t.string   "cvv_result_message"
    t.boolean  "success"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end
end
