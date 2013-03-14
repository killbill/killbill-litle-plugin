class Integer
  def base(b)
    self < b ? [self] : (self/b).base(b) + [self%b]
  end
end

module Killbill::Litle
  class Utils
    # Use base 62 to be safe on the Litle side
    BASE62 = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a

    def self.compact_uuid(uuid)
      uuid = uuid.gsub(/-/, '')
      uuid.hex.base(62).map{ |i| BASE62[i].chr } * ''
    end

    def self.unpack_uuid(base62_uuid)
      as_hex = base62_uuid.split(//).inject(0) { |i,e| i*62 + BASE62.index(e[0]) }
      ("%x" % as_hex).insert(8, "-").insert(13, "-").insert(18, "-").insert(23, "-")
    end
  end
end
