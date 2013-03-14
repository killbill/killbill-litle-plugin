module Killbill::Litle
  class Utils
    def self.compact_uuid(uuid)
      [[uuid].pack("H*")].pack("m").delete("\n")
    end

    def self.unpack_uuid(base64_uuid)
      base64_uuid.unpack("m").first.unpack("H*")
    end
  end
end
