require 'spec_helper'

ActiveMerchant::Billing::Base.mode = :test

describe Killbill::Litle::PaymentPlugin do

  include ::Killbill::Plugin::ActiveMerchant::RSpec

  before(:all) do
    ::Killbill::Litle::LitlePaymentMethod.delete_all
    ::Killbill::Litle::LitleResponse.delete_all
    ::Killbill::Litle::LitleTransaction.delete_all
  end

  after(:all) do
    puts 'orderId,litleTxnId,api_call,message'
    ::Killbill::Litle::LitleResponse.all.each do |response|
      next if response.params_litle_txn_id.blank?
      puts "#{response.params_order_id},#{response.params_litle_txn_id},#{response.api_call},#{response.message}"
    end
  end

  before(:each) do
    @call_context = build_call_context

    @properties = []
    @pm = create_payment_method(::Killbill::Litle::LitlePaymentMethod, nil, @call_context.tenant_id, [build_property(:skip_gw, true)], {}, false)
    @currency = 'USD'

    kb_payment_id = SecureRandom.uuid
    1.upto(8) do
      @kb_payment = @plugin.kb_apis.proxied_services[:payment_api].add_payment(kb_payment_id)
    end
  end

  after(:each) do
    @plugin.stop_plugin
  end

  it 'passes certification for order id 1' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '4457010000000009',
                                         :cc_first_name => 'John & Mary',
                                         :cc_last_name => 'Smith',
                                         :cc_type => 'visa',
                                         :cc_exp_month => '01',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '349',
                                         :address1 => '1 Main St.',
                                         :city => 'Burlington',
                                         :state => 'MA',
                                         :zip => '01803-3747',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {
        :avs => 'X',
        :cvv => 'M'
    }

    txn_nb = 0

    txn_nb = auth_assertions('1', 101.00, txn_nb, properties, assertions)

    # 1: authorize avs
    txn_nb = avs_assertions('1', txn_nb, properties, assertions)

    sale_assertions('1', 101.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 2' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '5112010000000003',
                                         :cc_first_name => 'Mike J.',
                                         :cc_last_name => 'Hammer',
                                         :cc_type => 'master',
                                         :cc_exp_month => '02',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '261',
                                         :address1 => '2 Main St.',
                                         :city => 'Riverside',
                                         :state => 'RI',
                                         :zip => '02915',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {
        :avs => 'Z',
        :cvv => 'M'
    }

    txn_nb = 0

    txn_nb = auth_assertions('2', 101.00, txn_nb, properties, assertions)

    # 2: authorize avs
    txn_nb = avs_assertions('2', txn_nb, properties, assertions)

    sale_assertions('2', 101.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 3' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '6011010000000003',
                                         :cc_first_name => 'Eileen',
                                         :cc_last_name => 'Jones',
                                         :cc_type => 'discover',
                                         :cc_exp_month => '03',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '758',
                                         :address1 => '3 Main St.',
                                         :city => 'Bloomfield',
                                         :state => 'CT',
                                         :zip => '06002',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {
        :avs => 'Z',
        :cvv => 'M'
    }

    txn_nb = 0

    auth_assertions('3', 101.00, txn_nb, properties, assertions)

    # 3: authorize avs
    txn_nb = avs_assertions('3', txn_nb, properties, assertions)

    sale_assertions('3', 101.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 4' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '375001000000005',
                                         :cc_first_name => 'Bob',
                                         :cc_last_name => 'Black',
                                         :cc_type => 'american_express',
                                         :cc_exp_month => '04',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '261',
                                         :address1 => '4 Main St.',
                                         :city => 'Laurel',
                                         :state => 'MD',
                                         :zip => '20708',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {
        :avs => 'A',
        :cvv => nil
    }

    txn_nb = 0

    txn_nb = auth_assertions('4', 101.00, txn_nb, properties, assertions)

    # 3: authorize avs
    txn_nb = avs_assertions('4', txn_nb, properties, assertions)

    sale_assertions('4', 101.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 5' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '4100200300011001',
                                         :cc_type => 'visa',
                                         :cc_exp_month => '05',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '463'
                                     },
                                     false)

    assertions = {
        :avs => 'U',
        :cvv => 'M'
    }

    txn_nb = 0

    txn_nb = auth_assertions('5', 101.00, txn_nb, properties, assertions)

    # 3: authorize avs
    txn_nb = avs_assertions('5', txn_nb, properties, assertions)

    sale_assertions('5', 101.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 6' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '4457010100000008',
                                         :cc_first_name => 'Joe',
                                         :cc_last_name => 'Green',
                                         :cc_type => 'visa',
                                         :cc_exp_month => '06',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '992',
                                         :address1 => '6 Main St.',
                                         :city => 'Derry',
                                         :state => 'NH',
                                         :zip => '03038',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Insufficient Funds',
        :avs => 'I',
        :cvv => 'P'
    }

    txn_nb = 0

    txn_nb = authorize_assertions('6', 101.00, txn_nb, properties, assertions)
    txn_nb = purchase_assertions('6', 101.00, txn_nb, properties, assertions)

    assertions = {
        :success => false,
        :message => 'No transaction found with specified litleTxnId'
    }

    # Cannot be run since there is no successful Auth nor Purchase
    # void_assertions('6', txn_nb, properties, assertions)
  end

  it 'passes certification for order id 7' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '5112010100000002',
                                         :cc_first_name => 'Jane',
                                         :cc_last_name => 'Murray',
                                         :cc_type => 'master',
                                         :cc_exp_month => '07',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '992',
                                         :address1 => '7 Main St.',
                                         :city => 'Amesbury',
                                         :state => 'MA',
                                         :zip => '01913',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Invalid Account Number',
        :avs => 'I',
        :cvv => 'N'
    }

    txn_nb = 0

    txn_nb = authorize_assertions('7', 101.00, txn_nb, properties, assertions)
    txn_nb = avs_assertions('7', txn_nb, properties, assertions)
    purchase_assertions('7', 101.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 8' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '6011010100000002',
                                         :cc_first_name => 'Mark',
                                         :cc_last_name => 'Johnson',
                                         :cc_type => 'discover',
                                         :cc_exp_month => '08',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '184',
                                         :address1 => '8 Main St.',
                                         :city => 'Manchester',
                                         :state => 'MH',
                                         :zip => '03101',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Call Discover',
        :avs => 'I',
        :cvv => 'P'
    }

    txn_nb = 0

    txn_nb = authorize_assertions('8', 101.00, txn_nb, properties, assertions)
    txn_nb = avs_assertions('8', txn_nb, properties, assertions)
    purchase_assertions('8', 101.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 9' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '375001010000003',
                                         :cc_first_name => 'James',
                                         :cc_last_name => 'Miller',
                                         :cc_type => 'american_express',
                                         :cc_exp_month => '09',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '0421',
                                         :address1 => '9 Main St.',
                                         :city => 'Boston',
                                         :state => 'MA',
                                         :zip => '02134',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Pick Up Card',
        :avs => 'I'
    }

    txn_nb = 0

    txn_nb = authorize_assertions('9', 101.00, txn_nb, properties, assertions)
    txn_nb = avs_assertions('9', txn_nb, properties, assertions)
    purchase_assertions('9', 101.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 10' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '4457010140000141',
                                         :cc_type => 'visa',
                                         :cc_exp_month => '09',
                                         :cc_exp_year => '2021',
                                         :allow_partial_auth => true,
                                     },
                                     false)

    assertions = {
        :success => true,
        :message => 'Partially Approved',
        :approvedAmount => 32000,
    }

    txn_nb = 0

    txn_nb = authorize_assertions('10', 400.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 11' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '5112010140000004',
                                         :cc_type => 'master',
                                         :cc_exp_month => '11',
                                         :cc_exp_year => '2021',
                                         :allow_partial_auth => true,
                                     },
                                     false)

    assertions = {
        :success => true,
        :message => 'Partially Approved',
        :approvedAmount => 48000,
    }

    txn_nb = 0

    txn_nb = authorize_assertions('11', 600.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 12' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '375001014000009',
                                         :cc_type => 'american_express',
                                         :cc_exp_month => '04',
                                         :cc_exp_year => '2021',
                                         :allow_partial_auth => true,
                                     },
                                     false)

    assertions = {
        :success => true,
        :message => 'Partially Approved',
        :approvedAmount => 40000,
    }

    txn_nb = 0

    txn_nb = authorize_assertions('12', 500.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 13' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '6011010140000004',
                                         :cc_type => 'discover',
                                         :cc_exp_month => '08',
                                         :cc_exp_year => '2021',
                                         :allow_partial_auth => true,
                                     },
                                     false)

    assertions = {
        :success => true,
        :message => 'Partially Approved',
        :approvedAmount => 12000,
    }

    txn_nb = 0

    txn_nb = authorize_assertions('13', 150.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 32' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '4457010000000009',
                                         :cc_first_name => 'John',
                                         :cc_last_name => 'Smith',
                                         :cc_type => 'visa',
                                         :cc_exp_month => '01',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '349',
                                         :address1 => '1 Main St.',
                                         :city => 'Burlington',
                                         :state => 'MA',
                                         :zip => '01803-3747',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {
        :message => 'Approved'
    }

    txn_nb = 0

    txn_nb = authorize_assertions('32', 100.10, txn_nb, properties, assertions)

    properties << build_property(:linked_transaction_type, :authorize)

    assertions = {
        :success => true,
        :code => '000',
        :message => 'Approved'
    }

    txn_nb = capture_assertions('32A', 50.50, txn_nb, properties, assertions)

    properties << build_property(:linked_transaction_type, :authorize)

    assertions = {
        :success => true,
        :code => '111',
        :message => 'Authorization amount has already been depleted'
    }
    void_assertions('32B', txn_nb, properties, assertions)
    # expected: "Authorization amount has already been depleted"
    # got: "Approved"
    # Vantiv is aware of this result
  end

  it 'passes certification for order id 33' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '5112010000000003',
                                         :cc_first_name => 'Mike J.',
                                         :cc_last_name => 'Hammer',
                                         :cc_type => 'master',
                                         :cc_exp_month => '02',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '261',
                                         :address1 => '2 Main St.',
                                         :city => 'Riverside',
                                         :state => 'RI',
                                         :zip => '02915',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {}

    txn_nb = 0

    txn_nb = authorize_assertions('33', 200.20, txn_nb, properties, assertions)

    properties << build_property(:linked_transaction_type, :authorize)

    void_assertions('33A', txn_nb, properties, assertions)
  end

  it 'passes certification for order id 34' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '6011010000000003',
                                         :cc_first_name => 'Eileen',
                                         :cc_last_name => 'Jones',
                                         :cc_type => 'discover',
                                         :cc_exp_month => '03',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '261',
                                         :address1 => '3 Main St.',
                                         :city => 'Bloomfield',
                                         :state => 'CT',
                                         :zip => '06002',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {}

    txn_nb = 0

    txn_nb = authorize_assertions('34', 300.30, txn_nb, properties, assertions)

    properties << build_property(:linked_transaction_type, :authorize)

    void_assertions('34A', txn_nb, properties, assertions)
  end

  it 'passes certification for order id 35' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '375001000000005',
                                         :cc_first_name => 'Bob',
                                         :cc_last_name => 'Black',
                                         :cc_type => 'american_express',
                                         :cc_exp_month => '04',
                                         :cc_exp_year => '2021',
                                         :address1 => '4 Main St.',
                                         :city => 'Laurel',
                                         :state => 'MD',
                                         :zip => '20708',
                                         :country => 'US'
                                     },
                                     false)

    assertions = {
        :success => true,
        :message => 'Approved'
    }

    txn_nb = 0

    txn_nb = authorize_assertions('35', 101.00, txn_nb, properties, assertions)

    assertions = {
        :success => true,
        :message => 'Approved'
    }

    properties << build_property(:linked_transaction_type, :authorize)

    txn_nb = capture_assertions('35A', 50.50, txn_nb, properties, assertions)

    assertions = {
        :success => true,
        :message => 'Reversal amount does not match authorization amount'
    }

    properties << build_property(:amount, 50.50)
    properties << build_property(:linked_transaction_type, :authorize)

    # ActiveMerchant doesn't pass an amount in the void call
    void_assertions('35B', txn_nb, properties, assertions)
    # expected: "Reversal amount does not match Authorization amount"
    # got: "Approved"
    # Vantiv is aware of this result
  end

  it 'passes certification for order id 36' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '375000026600004',
                                         :cc_type => 'american_express',
                                         :cc_exp_month => '05',
                                         :cc_exp_year => '2021'
                                     },
                                     false)

    assertions = {
        :success => true,
        :message => 'Approved'
    }

    txn_nb = 0

    txn_nb = authorize_assertions('36', 205.00, txn_nb, properties, assertions)

    assertions = {
        :success => true,
        :message => 'Reversal amount does not match authorization amount'
    }

    properties << build_property(:linked_transaction_type, :authorize)
    properties << build_property(:amount, 10000)

    # ActiveMerchant doesn't pass an amount in the void call
    void_assertions('36A', txn_nb, properties, assertions)
    # expected: "Reversal amount does not match Authorization amount"
    # got: "Approved"
    # Vantiv is aware of this result
  end

  # Conflicts with 52?
  it 'passes certification for order id 50' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '4457119922390123'
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Account number was successfully registered'
    }

    store_assertions('50', properties, assertions)
    # expected: "Account number was successfully registered"
    # got: "Account number was previously registered"
    # Vantiv is aware of this result
  end

  it 'passes certification for order id 51' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '4457119999999999'
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Credit card number was invalid'
    }

    store_assertions('51', properties, assertions)
  end

  it 'passes certification for order id 52' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '4457119922390123'
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Account number was previously registered'
    }

    store_assertions('52', properties, assertions)
  end

  it 'passes certification for order id 55' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '5435101234510196',
                                         :cc_type => 'master',
                                         :cc_exp_month => '11',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '987'
                                     },
                                     false)

    assertions = {
        :message => 'Approved',
        :token_message => 'Account number was successfully registered',
        :token_response_code => '801'
    }

    txn_nb = 0

    authorize_assertions('55', 150.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 56' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '5435109999999999',
                                         :cc_type => 'master',
                                         :cc_exp_month => '11',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '987'
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Invalid Account Number'
    }

    txn_nb = 0

    authorize_assertions('56', 150.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 57 and 58' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '5435101234510196',
                                         :cc_type => 'master',
                                         :cc_exp_month => '11',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '987'
                                     },
                                     false)

    assertions = {
        :message => 'Approved',
        :token_message => 'Account number was previously registered',
        :token_response_code => '802'
    }

    txn_nb = 0

    authorize_assertions('57', 150.00, txn_nb, properties, assertions)

    properties << build_property(:linked_transaction_type, :authorize)

    assertions = {
        :code => '000',
        :message => 'Approved'
    }

    authorize_assertions('58', 150.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 59' do
    properties = build_pm_properties(nil,
                                     {
                                         :token => '1111000100092332',
                                         :cc_exp_month => '11',
                                         :cc_exp_year => '2021'
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Token was not found',
        :code => '822'
    }

    txn_nb = 0

    authorize_assertions('59', 150.00, txn_nb, properties, assertions)
  end

  it 'passes certification for order id 60' do
    properties = build_pm_properties(nil,
                                     {
                                         :token => '1112000100000085',
                                         :cc_exp_month => '11',
                                         :cc_exp_year => '2021'
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Token was invalid',
        :code => '823'
    }

    txn_nb = 0

    authorize_assertions('60', 150.00, txn_nb, properties, assertions)
  end

  it 'passes certification for eProtect test case 13' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_exp_month => '12',
                                         :cc_exp_year => '2030',
                                         :cc_verification_value => '987',
                                         # this paypageRegistrationId should be the one received in eProtect's Test Case #1
                                         :paypageRegistrationId => 'SUhpblR1K1JjSVQyRWx0WUxhTUlsT2hkd3c4bVN2YXlWNkZZa0M4Ly9uQzNuZkFEOVpBNkM1c2dGcGJZbnBraA=='
                                     },
                                     false)

    assertions = {
        :success => true,
        :message => 'Approved'
    }

    txn_nb = 0

    authorize_assertions('13', 100.10, txn_nb, properties, assertions)
  end

  it 'passes certification for eProtect test case 14' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_exp_month => '12',
                                         :cc_exp_year => '2030',
                                         :cc_verification_value => '987',
                                         :paypageRegistrationId => 'cDZJcmd1VjNlYXNaSlRMTGpocVZQY1NWVXE4ZW5UTko4NU9KK3p1L1p1Vzg4YzVPQVlSUHNITG1JN2I0NzlyTg=='
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Token was not found'
    }

    txn_nb = 0

    authorize_assertions('14', 100.10, txn_nb, properties, assertions)
  end

  it 'passes certification for eProtect test case 15' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_exp_month => '12',
                                         :cc_exp_year => '2030',
                                         :cc_verification_value => '987',
                                         :paypageRegistrationId => 'RGFQNCt6U1d1M21SeVByVTM4dHlHb1FsVkUrSmpnWXhNY0o5UkMzRlZFanZiUHVnYjN1enJXbG1WSDF4aXlNcA=='
                                     },
                                     false)

    assertions = {
        :success => false,
        :message => 'Expired paypage registration id'
    }

    txn_nb = 0

    authorize_assertions('15', 100.10, txn_nb, properties, assertions)
  end

  it 'passes certification for apple pay' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '4457010000000009',
                                         :cc_first_name => 'John',
                                         :cc_last_name => 'Smith',
                                         :cc_type => 'visa',
                                         :cc_exp_month => '01',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '349',
                                         :address1 => '1 Main St.',
                                         :city => 'Burlington',
                                         :state => 'MA',
                                         :zip => '01803-3747',
                                         :country => 'US',
                                         :payment_cryptogram => 'dGhlIHF1aWNrIGJyb3duIGZveCBqdW1wZWQgb3ZlciB0aGUgbGF6eSBkb2cK',
                                     },
                                     false)

    assertions = {}

    txn_nb = 0

    txn_nb = authorize_assertions('applepay', 100.10, txn_nb, properties, assertions)
  end

  it 'passes certification for android pay merchant decryption' do
    properties = build_pm_properties(nil,
                                     {
                                         :cc_number => '5454545454545454', # dpan
                                         :cc_first_name => 'John',
                                         :cc_last_name => 'Smith',
                                         :cc_type => 'master',  # needs to be inferred from dpan
                                         :cc_exp_month => '01',
                                         :cc_exp_year => '2021',
                                         :cc_verification_value => '123',
                                         :address1 => '1 Main St.',
                                         :city => 'Burlington',
                                         :state => 'MA',
                                         :zip => '01803-3747',
                                         :country => 'US',
                                         :payment_cryptogram => 'dGhlIHF1aWNrIGJyb3duIGZveCBqdW1wZWQgb3ZlciB0aGUgbGF6eSBkb2cK',
                                         :order_source => 'androidpay',
                                     },
                                     false)

    assertions = {}

    txn_nb = 0

    txn_nb = authorize_assertions('androidpay', 100.10, txn_nb, properties, assertions)
  end

  private

  def avs_assertions(order_id, txn_nb, properties, assertions = {})
    authorize_assertions(order_id, 0, txn_nb, properties, assertions)
  end

  def auth_assertions(order_id, amount, txn_nb, properties, assertions = {})
    assertions = assertions.clone

    # 1: authorize
    txn_nb = authorize_assertions(order_id, amount, txn_nb, properties, assertions)

    # No more AVS / CVV checks
    assertions.delete(:avs)
    assertions.delete(:cvv)

    # 1A: capture
    txn_nb = capture_assertions("#{order_id}A", amount, txn_nb, properties, assertions)

    # 1B: credit
    txn_nb = credit_assertions("#{order_id}B", amount, txn_nb, properties, assertions)

    # 1C: void
    void_assertions("#{order_id}C", txn_nb, properties, assertions)
  end

  def sale_assertions(order_id, amount, txn_nb, properties, assertions = {})
    assertions = assertions.clone

    # 1: sale
    txn_nb = purchase_assertions(order_id, amount, txn_nb, properties, assertions)

    # No more AVS / CVV checks
    assertions.delete(:avs)
    assertions.delete(:cvv)

    # 1B: credit
    txn_nb = credit_assertions("#{order_id}B", amount, txn_nb, properties, assertions)

    # 1C: void
    void_assertions("#{order_id}C", txn_nb, properties, assertions)
  end

  def authorize_assertions(order_id, amount, txn_nb, properties, assertions = {})
    properties = properties.clone
    properties << build_property(:order_id, order_id + " (" + SecureRandom.hex(6) + ")")

    payment_response = @plugin.authorize_payment(@pm.kb_account_id,
                                                 @kb_payment.id,
                                                 @kb_payment.transactions[txn_nb].id,
                                                 @pm.kb_payment_method_id,
                                                 amount,
                                                 @currency,
                                                 properties,
                                                 @call_context)
    common_checks(payment_response, assertions)

    txn_nb + 1
  end

  def capture_assertions(order_id, amount, txn_nb, properties, assertions = {})
    properties = properties.clone
    properties << build_property(:order_id, order_id + " (" + SecureRandom.hex(6) + ")")

    payment_response = @plugin.capture_payment(@pm.kb_account_id,
                                               @kb_payment.id,
                                               @kb_payment.transactions[txn_nb].id,
                                               @pm.kb_payment_method_id,
                                               amount,
                                               @currency,
                                               properties,
                                               @call_context)
    common_checks(payment_response, assertions)

    txn_nb + 1
  end

  def purchase_assertions(order_id, amount, txn_nb, properties, assertions = {})
    properties = properties.clone
    properties << build_property(:order_id, order_id + " (" + SecureRandom.hex(6) + ")")

    payment_response = @plugin.purchase_payment(@pm.kb_account_id,
                                                @kb_payment.id,
                                                @kb_payment.transactions[txn_nb].id,
                                                @pm.kb_payment_method_id,
                                                amount,
                                                @currency,
                                                properties,
                                                @call_context)
    common_checks(payment_response, assertions)

    txn_nb + 1
  end

  def credit_assertions(order_id, amount, txn_nb, properties, assertions = {})
    properties = properties.clone
    properties << build_property(:order_id, order_id + " (" + SecureRandom.hex(6) + ")")

    payment_response = @plugin.refund_payment(@pm.kb_account_id,
                                              @kb_payment.id,
                                              @kb_payment.transactions[txn_nb].id,
                                              @pm.kb_payment_method_id,
                                              amount,
                                              @currency,
                                              properties,
                                              @call_context)
    common_checks(payment_response, assertions)

    txn_nb + 1
  end

  def void_assertions(order_id, txn_nb, properties, assertions = {})
    properties = properties.clone
    properties << build_property(:order_id, order_id + " (" + SecureRandom.hex(6) + ")")

    payment_response = @plugin.void_payment(@pm.kb_account_id,
                                            @kb_payment.id,
                                            @kb_payment.transactions[txn_nb].id,
                                            @pm.kb_payment_method_id,
                                            properties,
                                            @call_context)
    common_checks(payment_response, assertions)

    txn_nb + 1
  end

  def common_checks(payment_response, assertions = {})
    assertions[:success] = true if assertions[:success].nil?
    payment_response.status.should eq(assertions[:success] ? :PROCESSED : :ERROR), payment_response.gateway_error
    payment_response.gateway_error.should == (assertions[:message] || 'Approved')
    check_property(payment_response.properties, 'avsResultCode', assertions[:avs]) if assertions[:avs]
    check_property(payment_response.properties, 'cvvResultCode', assertions[:cvv]) if assertions[:cvv]
    check_property(payment_response.properties, 'approvedAmount', assertions[:approvedAmount]) if assertions[:approvedAmount]
  end

  def check_property(properties, key, value)
    (properties.find { |prop| prop.key == key }).value.should == value
  end

  def store_assertions(order_id, properties, assertions = {})
    properties = properties.clone
    properties << build_property(:order_id, order_id + " (" + SecureRandom.hex(6) + ")")

    info = Killbill::Plugin::Model::PaymentMethodPlugin.new
    info.properties = []

    @plugin.add_payment_method(@pm.kb_account_id,
                               @pm.kb_payment_method_id,
                               info,
                               true,
                               properties,
                               @call_context)
  rescue => e
    e.message.should == assertions[:message]
  ensure
    ::Killbill::Litle::LitleResponse.last.message.should == assertions[:message]
  end
end
