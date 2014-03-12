[![Build Status](https://travis-ci.org/killbill/killbill-litle-plugin.png)](https://travis-ci.org/killbill/killbill-litle-plugin)
[![Code Climate](https://codeclimate.com/github/killbill/killbill-litle-plugin.png)](https://codeclimate.com/github/killbill/killbill-litle-plugin)

killbill-litle-plugin
=====================

Plugin to use Litle &amp; Co. as a gateway.

Release builds are available on [Maven Central](http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22org.kill-bill.billing.plugin.ruby%22%20AND%20a%3A%22litle-plugin%22) with coordinates `org.kill-bill.billing.plugin.ruby:litle-plugin`.

Requirements
------------

The plugin needs a database. The latest version of the schema can be found here: https://raw.github.com/killbill/killbill-litle-plugin/master/db/ddl.sql.

Usage
-----

Go to http://$HOST:8080/plugins/killbill-litle?kb_account_id=13d26090-b8d7-11e2-9e96-0800200c9a66 and enter your credit card information.

Then, save the token in Kill Bill (only `paypageRegistrationId` is required in the properties):

```
curl -v \
     -X POST \
     -H "Content-Type: application/json" \
     -H "X-Killbill-CreatedBy: Web server" \
     -H "X-Killbill-Reason: New account" \
     --data-binary '{
       "pluginName": "killbill-litle",
       "pluginInfo": {
         "properties": [
           {
             "key": "paypageRegistrationId",
             "value": "t3GER3BP3JHLASZe"
           },
           {
             "key": "ccFirstName",
             "value": "John"
           },
           {
             "key": "ccLastName",
             "value": "Doe"
           },
           {
             "key": "ccType",
             "value": "VISA"
           },
           {
             "key": "ccExpMonth",
             "value": 12
           },
           {
             "key": "ccExpYear",
             "value": 2015
           },
           {
             "key": "ccLast4",
             "value": 1234
           },
           {
             "key": "address1",
             "value": "5, oakriu road"
           },
           {
             "key": "address2",
             "value": "apt. 298"
           },
           {
             "key": "city",
             "value": "Gdio Foia"
           },
           {
             "key": "state",
             "value": "FL"
           },
           {
             "key": "zip",
             "value": "49302"
           },
           {
             "key": "country",
             "value": "IFP"
           }
         ]
       }
     }' \
     "http://$HOST:8080/1.0/kb/accounts/13d26090-b8d7-11e2-9e96-0800200c9a66/paymentMethods?isDefault=true"
```

Configuration
-------------

The plugin expects a `litle.yml` configuration file containing the following:

```
:litle:
  :merchant_id:
    :USD: 'your-merchant-id-USD'  
    :EUR: 'your-merchant-id-EURO'
  :password: 'your-password'
  :username: 'your-username'
  # Optional, if you are using PayPage
  :secure_page_url: 'litle-secure-page-url'
  :paypage_id:
    :USD: 'litle-paypage-id-USD'
    :EUR: 'litle-paypage-id-EURO'
  :log_file: '/var/tmp/litle.log'
  # Switch to false for production
  :test: true

:database:
  :adapter: 'sqlite3'
  :database: 'test.db'
# For MySQL
#  :adapter: 'jdbc'
#  :username: 'your-username'
#  :password: 'your-password'
#  :driver: 'com.mysql.jdbc.Driver'
#  :url: 'jdbc:mysql://127.0.0.1:3306/your-database'
```

By default, the plugin will look at the plugin directory root (where `killbill.properties` is located) to find this file.
Alternatively, set the Kill Bill system property `-Dorg.killbill.billing.osgi.bundles.jruby.conf.dir=/my/directory` to specify another location.

