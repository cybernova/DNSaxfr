DNSaxfr
====

<a href="https://i.imgur.com/iqPJk8U.png?1"><img src="https://i.imgur.com/iqPJk8U.png?1" /></a>

Shell script for testing DNS zone transfer misconfiguration.

Details of the issue and how to fix it, can be found here: https://www.us-cert.gov/ncas/alerts/TA15-103A

## Getting started

1) Clone the repository using git or download it manually

2) Unzip the repository and set the execution permission to the script:

```bash
 $chmod +x DNSaxfr.sh
```
3) Execute the script using the syntax as follows

Usage and Options
-----------------

***Usage:***

```
./DNSaxfr.sh [OPTION...][DOMAIN...]

```

* **0 Arguments:**

The script reads from stdin and writes on stdout, it takes one domain to test per line.

* **1+ Arguments:**

The script tests every domain specified as argument.

***Options:***

```

-c COUNTRY_CODE Test Alexa top 50 sites by country
-e              Make the script output exportable to a file
-f FILE         Alexa's top 1M sites .csv file. To use with -m option
-h              Display the help and exit
-m RANGE        Test Alexa's top 1M sites. RANGE examples: 1 (start to test from 1st) or 354,400 (test from 354th to 400th)
-n              Numeric address format for name servers
-r MAXDEPTH     Test recursively every subdomain of a vulnerable domain, descend at most MAXDEPTH levels. 0 means no limit
-x REGEXP       Do not test domains that match with regexp
-z              Save zone transfer data in a directory named as the vulnerable domain

```

## Examples

```bash
andrea@Workstation:~/Desktop$ ./DNSaxfr.sh -c IT -x 'google'
DOMAIN youtube.com: ns2.google.com. ns3.google.com. ns1.google.com. ns4.google.com. NOT VULNERABLE!
DOMAIN facebook.com: a.ns.facebook.com. b.ns.facebook.com. NOT VULNERABLE!
DOMAIN amazon.it: ns1.p31.dynect.net. ns2.p31.dynect.net. ns3.p31.dynect.net. pdns6.ultradns.co.uk. pdns2.ultradns.net. ns4.p31.dynect.net. pdns5.ultradns.info. pdns3.ultradns.org. pdns4.ultradns.org. pdns1.ultradns.net. NOT VULNERABLE!
DOMAIN wikipedia.org: ns2.wikimedia.org. ns0.wikimedia.org. ns1.wikimedia.org. NOT VULNERABLE!
...
```
```bash
andrea@Workstation:~/Desktop$ ./DNSaxfr.sh -m 110,112 2>/dev/null
INFO: Downloading from Amazon top 1 milion sites list...
INFO: Alexa's top 1m file path: /home/andrea/Desktop/top-1m.csv 
TIP: Use in future the -f option
DOMAIN google.nl: ns4.google.com. ns2.google.com. ns3.google.com. ns1.google.com. NOT VULNERABLE!
DOMAIN google.com.eg: ns4.google.com. ns2.google.com. ns3.google.com. ns1.google.com. NOT VULNERABLE!
DOMAIN nytimes.com: ns1.p24.dynect.net. dns-plx.sea1.nytimes.com. dns-plx.ewr1.nytimes.com. ns3.p24.dynect.net. ns4.p24.dynect.net. ns2.p24.dynect.net. NOT VULNERABLE!
...
```


License and Donations
-------

Coded by Andrea Dari and licensed under GNU GPL v2.0

Support me for updates and new projects: <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=andreadari91%40gmail%2ecom&lc=IT&item_name=Andrea%20Dari%20FOSS%20developer%20support&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" alt="[paypal]" /></a> Thanks!
