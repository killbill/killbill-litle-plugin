killbill-litle-plugin
=====================

Plugin to use [Litle &amp; Co.](https://www.litle.com/) as a gateway.

Release builds are available on [Maven Central](http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22org.kill-bill.billing.plugin.ruby%22%20AND%20a%3A%22litle-plugin%22) with coordinates `org.kill-bill.billing.plugin.ruby:litle-plugin`.

Kill Bill compatibility
-----------------------

| Plugin version | Kill Bill version |
| -------------: | ----------------: |
| 2.x.y          | 0.14.z            |
| 3.x.y          | 0.16.z            |
| 4.x.y          | 0.18.z            |
| 5.x.y          | 0.20.z            |

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
  - :account_id: USD
    :merchant_id: "your-merchant-id-USD"
    :login: "your-username"
    :password: "your-password"
    :secure_page_url: "litle-secure-page-url"
    :paypage_id: "your-paypage-id-USD"
  - :account_id: EUR
    :merchant_id: "your-merchant-id-EUR"
    :login: "your-username"
    :password: "your-password"
    :secure_page_url: "litle-secure-page-url"
    :paypage_id: "your-paypage-id-EUR" 
:multicurrency:
  :USD: "USD"
  :EUR: "EUR"' \
     http://127.0.0.1:8080/1.0/kb/tenants/uploadPluginConfig/killbill-litle
```

`multicurrency` setting provides the mapping between transaction currency to `account_id`.  The default currency is the first key in the `multicurrency` config, in the example above, it is `"USD"`.  If `multicurrency` is not present, the default `account_id` will be the first `account_id` in `litle` dictionary.

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

Running the tests
-----------------

In order to run the certification and integration tests, you will need a valid merchant id and credentials. You will
also likely have received a URL to test with when signing up for the merchant id.

Then run the tests with:
```
LITLE_TEST=true \
LITLE_TEST_URL="<the URL>" \
LITLE_MERCHANT_ID="<your merchant id>" \
LITLE_LOGIN="<your login>" \
LITLE_PASSWORD="<your password>" \
bundle exec rspec
```
