[![Build Status](https://travis-ci.org/killbill/killbill-litle-plugin.png)](https://travis-ci.org/killbill/killbill-litle-plugin)
[![Code Climate](https://codeclimate.com/github/killbill/killbill-litle-plugin.png)](https://codeclimate.com/github/killbill/killbill-litle-plugin)

killbill-litle-plugin
=====================

Plugin to use Litle &amp; Co. as a gateway.

Configuration
-------------

The plugin expects a `litle.yml` configuration file containing the following:

```
:litle:
  :merchant_id: 'your-merchant-id'
  :password: 'your-password'
  :username: 'your-username'
  # Optional, if you are using PayPage
  :secure_page_url: 'litle-secure-page-url'
  :paypage_id: 'litle-paypage-id'
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
Alternatively, set the Kill Bill system property `-Dcom.ning.billing.osgi.bundles.jruby.conf.dir=/my/directory` to specify another location.

