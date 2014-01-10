require 'spec_helper'

describe Killbill::Litle::LitleResponse do
  before :all do
    Killbill::Litle::LitleResponse.delete_all
  end

  it 'should generate the right SQL query' do
    # Check count query (search query numeric)
    expected_query = "SELECT COUNT(DISTINCT \"litle_responses\".\"id\") FROM \"litle_responses\"  WHERE (((\"litle_responses\".\"params_litleonelineresponse_saleresponse_id\" = '1234' OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_litle_txn_id\" = '1234') OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_order_id\" = '1234') OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_auth_code\" = '1234') AND \"litle_responses\".\"api_call\" = 'charge' AND \"litle_responses\".\"success\" = 't' ORDER BY \"litle_responses\".\"id\""
    # Note that Kill Bill will pass a String, even for numeric types
    Killbill::Litle::LitleResponse.search_query('charge', '1234').to_sql.should == expected_query

    # Check query with results (search query numeric)
    expected_query = "SELECT  DISTINCT \"litle_responses\".* FROM \"litle_responses\"  WHERE (((\"litle_responses\".\"params_litleonelineresponse_saleresponse_id\" = '1234' OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_litle_txn_id\" = '1234') OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_order_id\" = '1234') OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_auth_code\" = '1234') AND \"litle_responses\".\"api_call\" = 'charge' AND \"litle_responses\".\"success\" = 't' ORDER BY \"litle_responses\".\"id\" LIMIT 10 OFFSET 0"
    # Note that Kill Bill will pass a String, even for numeric types
    Killbill::Litle::LitleResponse.search_query('charge', '1234', 0, 10).to_sql.should == expected_query

    # Check count query (search query string)
    expected_query = "SELECT COUNT(DISTINCT \"litle_responses\".\"id\") FROM \"litle_responses\"  WHERE (((\"litle_responses\".\"params_litleonelineresponse_saleresponse_id\" = 'XXX' OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_litle_txn_id\" = 'XXX') OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_order_id\" = 'XXX') OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_auth_code\" = 'XXX') AND \"litle_responses\".\"api_call\" = 'charge' AND \"litle_responses\".\"success\" = 't' ORDER BY \"litle_responses\".\"id\""
    Killbill::Litle::LitleResponse.search_query('charge', 'XXX').to_sql.should == expected_query

    # Check query with results (search query string)
    expected_query = "SELECT  DISTINCT \"litle_responses\".* FROM \"litle_responses\"  WHERE (((\"litle_responses\".\"params_litleonelineresponse_saleresponse_id\" = 'XXX' OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_litle_txn_id\" = 'XXX') OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_order_id\" = 'XXX') OR \"litle_responses\".\"params_litleonelineresponse_saleresponse_auth_code\" = 'XXX') AND \"litle_responses\".\"api_call\" = 'charge' AND \"litle_responses\".\"success\" = 't' ORDER BY \"litle_responses\".\"id\" LIMIT 10 OFFSET 0"
    Killbill::Litle::LitleResponse.search_query('charge', 'XXX', 0, 10).to_sql.should == expected_query
  end

  it 'should search all fields' do
    do_search('foo').size.should == 0

    pm = Killbill::Litle::LitleResponse.create :api_call => 'charge',
                                               :kb_payment_id => '11-22-33-44',
                                               :params_litleonelineresponse_saleresponse_id => '55-66-77-88',
                                               :params_litleonelineresponse_saleresponse_litle_txn_id => 38102343,
                                               :params_litleonelineresponse_saleresponse_order_id => 'order-id-1',
                                               :params_litleonelineresponse_saleresponse_auth_code => 'auth-code-1',
                                               :success => true

    # Wrong api_call
    ignored1 = Killbill::Litle::LitleResponse.create :api_call => 'add_payment_method',
                                                     :kb_payment_id => pm.kb_payment_id,
                                                     :params_litleonelineresponse_saleresponse_id => pm.params_litleonelineresponse_saleresponse_id,
                                                     :params_litleonelineresponse_saleresponse_litle_txn_id => pm.params_litleonelineresponse_saleresponse_litle_txn_id,
                                                     :params_litleonelineresponse_saleresponse_order_id => pm.params_litleonelineresponse_saleresponse_order_id,
                                                     :params_litleonelineresponse_saleresponse_auth_code => pm.params_litleonelineresponse_saleresponse_auth_code,
                                                     :success => true

    # Not successful
    ignored2 = Killbill::Litle::LitleResponse.create :api_call => 'charge',
                                                     :kb_payment_id => pm.kb_payment_id,
                                                     :params_litleonelineresponse_saleresponse_id => pm.params_litleonelineresponse_saleresponse_id,
                                                     :params_litleonelineresponse_saleresponse_litle_txn_id => pm.params_litleonelineresponse_saleresponse_litle_txn_id,
                                                     :params_litleonelineresponse_saleresponse_order_id => pm.params_litleonelineresponse_saleresponse_order_id,
                                                     :params_litleonelineresponse_saleresponse_auth_code => pm.params_litleonelineresponse_saleresponse_auth_code,
                                                     :success => false

    do_search('foo').size.should == 0
    do_search(pm.params_litleonelineresponse_saleresponse_id).size.should == 1
    do_search(pm.params_litleonelineresponse_saleresponse_litle_txn_id).size.should == 1
    do_search(pm.params_litleonelineresponse_saleresponse_order_id).size.should == 1
    do_search(pm.params_litleonelineresponse_saleresponse_auth_code).size.should == 1

    pm2 = Killbill::Litle::LitleResponse.create :api_call => 'charge',
                                                :kb_payment_id => '11-22-33-44',
                                                :params_litleonelineresponse_saleresponse_id => '11-22-33-44',
                                                :params_litleonelineresponse_saleresponse_litle_txn_id => pm.params_litleonelineresponse_saleresponse_litle_txn_id,
                                                :params_litleonelineresponse_saleresponse_order_id => 'order-id-2',
                                                :params_litleonelineresponse_saleresponse_auth_code => 'auth-code-2',
                                                :success => true

    do_search('foo').size.should == 0
    do_search(pm.params_litleonelineresponse_saleresponse_id).size.should == 1
    do_search(pm.params_litleonelineresponse_saleresponse_litle_txn_id).size.should == 2
    do_search(pm.params_litleonelineresponse_saleresponse_order_id).size.should == 1
    do_search(pm.params_litleonelineresponse_saleresponse_auth_code).size.should == 1
    do_search(pm2.params_litleonelineresponse_saleresponse_id).size.should == 1
    do_search(pm2.params_litleonelineresponse_saleresponse_litle_txn_id).size.should == 2
    do_search(pm2.params_litleonelineresponse_saleresponse_order_id).size.should == 1
    do_search(pm2.params_litleonelineresponse_saleresponse_auth_code).size.should == 1
  end

  private

  def do_search(search_key)
    pagination = Killbill::Litle::LitleResponse.search(search_key)
    pagination.current_offset.should == 0
    results = pagination.iterator.to_a
    pagination.total_nb_records.should == results.size
    results
  end
end
