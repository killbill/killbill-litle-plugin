require 'spec_helper'

describe Killbill::Litle do

  before :all do
    Killbill::Litle.initialize!
  end

  it 'should not make currency conversion' do
    Killbill::Litle.converted_currency(:USD).should be_false
    Killbill::Litle.converted_currency('usd').should be_false
    Killbill::Litle.converted_currency('USD').should be_false
  end

  it 'should make currency conversion' do
    Killbill::Litle.converted_currency(:BRL).should == 'USD'
    Killbill::Litle.converted_currency('brl').should == 'USD'
    Killbill::Litle.converted_currency('BRL').should == 'USD'
  end

end