killbill-litle-plugin
=====================

Plugin to use [Litle &amp; Co.](https://www.litle.com/) as a gateway.

Release builds are available on [Maven Central](http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22org.kill-bill.billing.plugin.ruby%22%20AND%20a%3A%22litle-plugin%22) with coordinates `org.kill-bill.billing.plugin.ruby:litle-plugin`.

Requirements
------------

The plugin needs a database. The latest version of the schema can be found [here](https://github.com/killbill/killbill-litle-plugin/blob/master/db/ddl.sql).

Configuration
-------------

```
curl -v \
     -X POST \
     -u admin:password \
     -H 'X-Killbill-ApiKey: bob' \
     -H 'X-Killbill-ApiSecret: lazar' \
     -H 'X-Killbill-CreatedBy: admin' \
     -H 'Content-Type: text/plain' \
     -d ':litle:
  :merchant_id:
    :USD: "your-merchant-id-USD"
    :EUR: "your-merchant-id-EURO"
  :password: "your-password"
  :username: "your-username"
  :secure_page_url: "litle-secure-page-url"
  :paypage_id:
    :USD: "litle-paypage-id-USD"
    :EUR: "litle-paypage-id-EURO"' \
     http://127.0.0.1:8080/1.0/kb/tenants/uploadPluginConfig/killbill-litle
```

To go to production, create a `litle.yml` configuration file under `/var/tmp/bundles/plugins/ruby/killbill-litle/x.y.z/` containing the following:

```
:litle:
  :test: false
```

Usage
-----

You would typically implement [Litle PayPage](https://www.litle.com/images/uploads/Paypage.pdf) to tokenize credit cards. 

After receiving the token from Litle, call:

```
curl -v \
     -X POST \
     -u admin:password \
     -H 'X-Killbill-ApiKey: bob' \
     -H 'X-Killbill-ApiSecret: lazar' \
     -H 'X-Killbill-CreatedBy: admin' \
     -H 'Content-Type: application/json' \
     -d '{
       "pluginName": "killbill-litle",
       "pluginInfo": {
         "properties": [{
           "key": "paypageRegistrationId",
           "value": "t3GER3BP3JHLASZe"
         }]
       }
     }' \
     "http://127.0.0.1:8080/1.0/kb/accounts/2a55045a-ce1d-4344-942d-b825536328f9/paymentMethods?isDefault=true"
```

An example implementation is exposed at:

```
http://127.0.0.1:8080/plugins/killbill-litle/form?kb_account_id=2a55045a-ce1d-4344-942d-b825536328f9&kb_tenant_id=a86d9fd1-718d-4178-a9eb-46c61aa2548f
```

To display the payment method details for that account, call:

```
curl -v \
     -u admin:password \
     -H 'X-Killbill-ApiKey: bob' \
     -H 'X-Killbill-ApiSecret: lazar' \
     -H 'Accept: application/json' \
     "http://127.0.0.1:8080/1.0/kb/accounts/2a55045a-ce1d-4344-942d-b825536328f9/paymentMethods?withPluginInfo=true"
```
