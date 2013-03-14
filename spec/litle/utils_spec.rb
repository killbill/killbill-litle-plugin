require 'spec_helper'

describe Killbill::Litle::Utils do
  it "should convert back and forth UUIDs" do
    uuid = SecureRandom.uuid
    packed = Killbill::Litle::Utils.compact_uuid(uuid)
    unpacked = Killbill::Litle::Utils.unpack_uuid(packed)
    unpacked.should == uuid
  end
end
