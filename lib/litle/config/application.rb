configure do
  # Usage: rackup -Ilib -E test
  if development? or test?
    Killbill::Litle.initialize! unless Killbill::Litle.initialized
  end
end

helpers do
  def plugin
    Killbill::Litle::PrivatePaymentPlugin.instance
  end

  def required_parameter!(parameter_name, parameter_value, message='must be specified!')
    halt 400, "#{parameter_name} #{message}" if parameter_value.blank?
  end
end

# http://127.0.0.1:9292/plugins/killbill-litle
get '/plugins/killbill-litle' do
  kb_account_id = request.GET['kb_account_id']
  required_parameter! :kb_account_id, kb_account_id

  secure_page_url = Killbill::Litle.config[:litle][:secure_page_url]
  required_parameter! :secure_page_url, secure_page_url, 'is not configured'

  # Allow currency override if needed
  currency = request.GET['currency'] || plugin.get_currency(kb_account_id)
  paypage_id = Killbill::Litle.config[:litle][:paypage_id][currency.to_sym]
  required_parameter! :paypage_id, paypage_id, "is not configured for currency #{currency.to_sym}"

  locals = {
      :currency => currency,
      :secure_page_url => secure_page_url,
      :paypage_id => paypage_id,
      :kb_account_id => kb_account_id,
      :merchant_txn_id => request.GET['merchant_txn_id'] || '1',
      :order_id => request.GET['order_id'] || '1',
      :report_group => request.GET['report_group'] || 'Default Report Group',
      :success_page => params[:successPage] || '/plugins/killbill-litle/checkout',
      :failure_page => params[:failurePage]
  }
  erb :paypage, :views => File.expand_path(File.dirname(__FILE__) + '/../views'), :locals => locals
end

post '/plugins/killbill-litle/checkout' do
  kb_account_id = request.POST['kb_account_id']
  response_paypage_registration_id = request.POST['response_paypage_registration_id']
  # Allow currency override if needed
  currency = request.POST['currency'] || plugin.get_currency(kb_account_id)

  {
      :kb_account_id => kb_account_id,
      :currency => currency,
      :response_paypage_registration_id => response_paypage_registration_id
  }.each { |k, v| required_parameter! k, v }

  pm = plugin.register_token! kb_account_id, currency, response_paypage_registration_id
  redirect "/plugins/killbill-litle/1.0/pms/#{pm.id}"
end

# curl -v http://127.0.0.1:9292/plugins/killbill-litle/1.0/pms/1
get '/plugins/killbill-litle/1.0/pms/:id', :provides => 'json' do
  if pm = Killbill::Litle::LitlePaymentMethod.find_by_id(params[:id].to_i)
    pm.to_json
  else
    status 404
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-litle/1.0/transactions/1
get '/plugins/killbill-litle/1.0/transactions/:id', :provides => 'json' do
  if transaction = Killbill::Litle::LitleTransaction.find_by_id(params[:id].to_i)
    transaction.to_json
  else
    status 404
  end
end
