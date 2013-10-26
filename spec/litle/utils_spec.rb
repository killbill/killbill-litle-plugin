require 'spec_helper'

describe Killbill::Litle::Utils do
  it "should convert back and forth UUIDs" do
    uuid = SecureRandom.uuid
    packed = Killbill::Litle::Utils.compact_uuid(uuid)
    unpacked = Killbill::Litle::Utils.unpack_uuid(packed)
    unpacked.should == uuid
  end

  it "should respect leading 0s" do
    uuid = "0ae18a4c-be57-44c3-84ba-a82962a2de03"
    0.upto(35) do |i|
      # Skip hyphens
      next if [8, 13, 18, 23].include?(i)
      uuid[i] = '0'
      packed = Killbill::Litle::Utils.compact_uuid(uuid)
      unpacked = Killbill::Litle::Utils.unpack_uuid(packed)
      unpacked.should == uuid
    end
  end
end
