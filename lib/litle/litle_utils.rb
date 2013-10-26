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

  # Closest from a streaming API as we can get with ActiveRecord
  class StreamyResultSet
    include Enumerable

    def initialize(limit, batch_size = 100, &delegate)
      @limit = limit
      @batch = [batch_size, limit].min
      @delegate = delegate
    end

    def each(&block)
      (0..(@limit - @batch)).step(@batch) do |i|
        result = @delegate.call(i, @batch)
        block.call(result)
        # Optimization: bail out if no more results
        break if result.nil? || result.empty?
      end if @batch > 0
      # Make sure to return DB connections to the Pool
      ActiveRecord::Base.connection.close
    end

    def to_a
      super.to_a.flatten
    end
  end
end
