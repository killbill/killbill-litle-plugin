require 'active_record'
require 'activemerchant'
require 'pathname'
require 'singleton'
require 'yaml'

require 'killbill'

require 'litle/config'
require 'litle/api'

require 'litle/models/litle_payment_method'
require 'litle/models/litle_response'
require 'litle/models/litle_transaction'

require 'litle/litle_utils'
require 'litle/gateway'

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end
