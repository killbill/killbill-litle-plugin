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
end

# http://127.0.0.1:9292/plugins/killbill-litle
get '/plugins/killbill-litle' do
  locals = {
    :secure_page_url => Killbill::Litle.config[:litle][:secure_page_url],
    :paypage_id => Killbill::Litle.config[:litle][:paypage_id],
    :kb_account_id => request.GET['kb_account_id'] || '1',
    :merchant_txn_id => request.GET['merchant_txn_id'] || '1',
    :order_id => request.GET['order_id'] || '1',
    :report_group => request.GET['report_group'] || 'Default Report Group',
    :success_page => params[:successPage] || '/plugins/killbill-litle/checkout',
    :failure_page => params[:failurePage]
  }
  erb :paypage, :views => File.expand_path(File.dirname(__FILE__) + '/../views'), :locals => locals
end

post '/plugins/killbill-litle/checkout' do
  data = request.POST

  begin
    pm = plugin.register_token! data['kb_account_id'], data['response_paypage_registration_id']
    redirect "/plugins/killbill-litle/1.0/pms/#{pm.id}"
  rescue => e
    halt 500, {'Content-Type' => 'text/plain'}, "Error: #{e}"
  end
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