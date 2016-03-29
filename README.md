DNSaxfr
====

Shell script for testing DNS zone transfer misconfiguration .

Details of the problem and how to fix it, can be found here: https://www.us-cert.gov/ncas/alerts/TA15-103A

## Getting started

First, clone the repository using git (recommended):

```bash
git clone https://github.com/cybernova/DNSaxfr/
```
or download the script manually.

Then set the execution permission to the script:

```bash
 $chmod +x DNSaxfr.sh
```

Usage and Options
-----------------

***Usage:***

The syntax is very simple:

```
./DNSaxfr.sh [OPTION...][DOMAIN...]

```

* **0 Arguments:**

The script acts like a filter, reads from stdin and writes on stdout, useful for using it in a pipeline.

**NOTE:** It takes one domain to test per line

* **1+ Arguments:**

The script tests every domain specified as argument, writing the output on stdout.

***Options:***

```
-b              Batch mode, useful for making the output readable when saved in a file
-c COUNTRY_CODE Test Alexa top 500 sites by country
-f FILE         Alexa's top 1M sites .csv file. To use in conjuction with -m option
-h              Display the help and exit
-i              Interactive mode
-m RANGE        Test Alexa top 1M sites. RANGE examples: 1 (start to test from 1st) or 354,400 (test from 354th to 400th)   
-r              Test recursively every subdomain of a vulnerable domain, drawing all in a customizable tree
-z              Save the zone transfer in a directory named as the domain vulnerable in the following form: domain_axfr.log

```

## Examples

```bash
andrea@Workstation:~/Desktop$ ./DNSaxfr.sh -rz unito.it
DOMAIN unito.it: albert.unito.it. VULNERABLE!
DOMAIN unito.it: dns.unito.it. moebius.to.infn.it. NOT VULNERABLE!
|--DOMAIN ac.unito.it.: albert.unito.it. VULNERABLE!
|  DOMAIN ac.unito.it.: dns.unito.it. NOT VULNERABLE!
|--DOMAIN agraria.unito.it.: albert.unito.it. VULNERABLE!
|  DOMAIN agraria.unito.it.: dns.unito.it. NOT VULNERABLE!
|--DOMAIN agriinnova.unito.it.: albert.unito.it. VULNERABLE!
|  DOMAIN agriinnova.unito.it.: dns.unito.it. NOT VULNERABLE!
...

andrea@Workstation:~/Desktop$ ./DNSaxfr.sh -zrm 997,999
Downloading from Amazon top 1 milion sites list...
File's path: /home/andrea/Desktop/top-1m.csv
DOMAIN express.pk: jill.ns.cloudflare.com. greg.ns.cloudflare.com. NOT VULNERABLE!
DOMAIN 114la.com: ns2.dnsv4.com. ns1.dnsv4.com. NOT VULNERABLE!
DOMAIN coupons.com: ns5-66.akam.net. ns4-67.akam.net. ns1-219.akam.net. ns7-64.akam.net. NOT VULNERABLE!

andrea@Workstation:~/Desktop$ ./DNSaxfr.sh -rm 100000,100002 -f top-1m.csv 
DOMAIN 4055.com: f1g1ns2.dnspod.net. f1g1ns1.dnspod.net. NOT VULNERABLE!
DOMAIN kickassfacts.com: ns1.kickassfacts.com. ns2.kickassfacts.com. NOT VULNERABLE!
DOMAIN qonlineshop.com: ns2.dezigndreamz.com. ns1.dezigndreamz.com. VULNERABLE!

```

## Tested Environments

* GNU/Linux

If you have successfully tested this script on others systems or platforms please let me know.

License and Donations
-------

Written by Andrea 'cybernova' Dari and licensed under GNU GPL v2.0

If you have found this script useful I gladly accept donations, also symbolic through Paypal:

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=andreadari91%40gmail%2ecom&lc=IT&item_name=Andrea%20Dari%20IT%20independent%20researcher&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" alt="[paypal]" /></a> or Bitcoin: 1B2KqKm4CgzRfSsXv7VmbmXD9XNQzzLaTW
