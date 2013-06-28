require 'spec_helper'

describe Killbill::Litle::LitlePaymentMethod do
  it 'should search all fields' do
    Killbill::Litle::LitlePaymentMethod.search('foo').size.should == 0

    pm = Killbill::Litle::LitlePaymentMethod.create :kb_account_id => '11-22-33-44',
                                                    :kb_payment_method_id => '55-66-77-88',
                                                    :litle_token => 38102343,
                                                    :cc_first_name => 'ccFirstName',
                                                    :cc_last_name => 'ccLastName',
                                                    :cc_type => 'ccType',
                                                    :cc_exp_month => 10,
                                                    :cc_exp_year => 11,
                                                    :cc_last_4 => 1234,
                                                    :address1 => 'address1',
                                                    :address2 => 'address2',
                                                    :city => 'city',
                                                    :state => 'state',
                                                    :zip => 'zip',
                                                    :country => 'country'

    Killbill::Litle::LitlePaymentMethod.search('foo').size.should == 0
    Killbill::Litle::LitlePaymentMethod.search(pm.litle_token).size.should == 1
    Killbill::Litle::LitlePaymentMethod.search('cc').size.should == 1
    Killbill::Litle::LitlePaymentMethod.search('address').size.should == 1
    Killbill::Litle::LitlePaymentMethod.search(2343).size.should == 1
    Killbill::Litle::LitlePaymentMethod.search('name').size.should == 1
    Killbill::Litle::LitlePaymentMethod.search('Name').size.should == 1

    pm2 = Killbill::Litle::LitlePaymentMethod.create :kb_account_id => '22-33-44-55',
                                                     :kb_payment_method_id => '66-77-88-99',
                                                     :litle_token => 49384029302,
                                                     :cc_first_name => 'ccFirstName',
                                                     :cc_last_name => 'ccLastName',
                                                     :cc_type => 'ccType',
                                                     :cc_exp_month => 10,
                                                     :cc_exp_year => 11,
                                                     :cc_last_4 => 1234,
                                                     :address1 => 'address1',
                                                     :address2 => 'address2',
                                                     :city => 'city',
                                                     :state => 'state',
                                                     :zip => 'zip',
                                                     :country => 'country'

    Killbill::Litle::LitlePaymentMethod.search('foo').size.should == 0
    Killbill::Litle::LitlePaymentMethod.search(pm.litle_token).size.should == 1
    Killbill::Litle::LitlePaymentMethod.search(pm2.litle_token).size.should == 1
    Killbill::Litle::LitlePaymentMethod.search('cc').size.should == 2
    Killbill::Litle::LitlePaymentMethod.search('address').size.should == 2
    Killbill::Litle::LitlePaymentMethod.search(2343).size.should == 1
    Killbill::Litle::LitlePaymentMethod.search('name').size.should == 2
    Killbill::Litle::LitlePaymentMethod.search('Name').size.should == 2
  end
end
