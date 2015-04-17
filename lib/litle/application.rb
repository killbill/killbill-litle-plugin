# -- encoding : utf-8 --

set :views, File.expand_path(File.dirname(__FILE__) + '/views')

include Killbill::Plugin::ActiveMerchant::Sinatra

configure do
  # Usage: rackup -Ilib -E test
  if development? or test?
    # Make sure the plugin is initialized
    plugin              = ::Killbill::Litle::PaymentPlugin.new
    plugin.logger       = Logger.new(STDOUT)
    plugin.logger.level = Logger::INFO
    plugin.conf_dir     = File.dirname(File.dirname(__FILE__)) + '/..'
    plugin.start_plugin
  end
end

helpers do
  def plugin(session = {})
    ::Killbill::Litle::PrivatePaymentPlugin.new(session)
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-litle/form
get '/plugins/killbill-litle/form', :provides => 'html' do
  kb_account_id = request.GET['kb_account_id']
  required_parameter! :kb_account_id, kb_account_id

  kb_tenant_id = request.GET['kb_tenant_id']
  kb_tenant = request.env['killbill_tenant']
  kb_tenant_id ||= kb_tenant.id.to_s unless kb_tenant.nil?

  currency = request.GET['currency'] || plugin.get_currency(kb_account_id)

  tenant_config = config(kb_tenant_id)
  litle_config = tenant_config[:litle].is_a?(Array) ? (tenant_config[:litle].find { |c| c[:account_id] == currency }) : tenant_config[:litle]

  paypage_id = litle_config[:paypage_id]
  required_parameter! :paypage_id, paypage_id, "is not configured for currency #{currency.to_sym}"

  secure_page_url = litle_config[:secure_page_url]
  required_parameter! :secure_page_url, secure_page_url, 'is not configured'

  locals = {
      :currency => currency,
      :secure_page_url => secure_page_url,
      :paypage_id => paypage_id,
      :kb_account_id => kb_account_id,
      :kb_tenant_id => kb_tenant_id,
      :merchant_txn_id => request.GET['merchant_txn_id'] || '1',
      :order_id => request.GET['order_id'] || '1',
      :report_group => request.GET['report_group'] || 'Default Report Group',
      :success_page => params[:successPage] || '/plugins/killbill-litle',
      :failure_page => params[:failurePage]
  }
  erb :paypage, :locals => locals
end

# This is mainly for testing. Your application should redirect from the PayPage checkout above
# to a custom endpoint where you call the Kill Bill add payment method JAX-RS API.
# If you really want to use this endpoint, you'll have to call the Kill Bill refresh payment methods API
# to get a Kill Bill payment method id assigned.
post '/plugins/killbill-litle' do
  pm = plugin.add_payment_method(params)

  status 201
  redirect '/plugins/killbill-litle/1.0/pms/' + pm.id.to_s
end

# curl -v http://127.0.0.1:9292/plugins/killbill-litle/1.0/pms/1
get '/plugins/killbill-litle/1.0/pms/:id', :provides => 'json' do
  if pm = ::Killbill::Litle::LitlePaymentMethod.find_by_id(params[:id].to_i)
    pm.to_json
  else
    status 404
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-litle/1.0/transactions/1
get '/plugins/killbill-litle/1.0/transactions/:id', :provides => 'json' do
  if transaction = ::Killbill::Litle::LitleTransaction.find_by_id(params[:id].to_i)
    transaction.to_json
  else
    status 404
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-litle/1.0/responses/1
get '/plugins/killbill-litle/1.0/responses/:id', :provides => 'json' do
  if transaction = ::Killbill::Litle::LitleResponse.find_by_id(params[:id].to_i)
    transaction.to_json
  else
    status 404
  end
end
