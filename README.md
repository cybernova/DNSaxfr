DNSaxfr
====

Shell script for testing DNS zone transfer misconfiguration .

Details of the problem and how to fix it, can be found here: https://www.us-cert.gov/ncas/alerts/TA15-103A

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

The syntax is very simple:

```
./DNSaxfr.sh [OPTION...][DOMAIN...]

```

* **0 Arguments:**

The script reads from stdin and writes on stdout, it takes one domain to test per line.

* **1+ Arguments:**

The script tests every domain specified as argument.

***Options:***

```

-b              Batch mode, makes the output readable when saved in a file"
-h              Display the help and exit"
-i              Interactive mode"
-r              Test recursively every subdomain of a vulnerable domain"
-z              Save the zone transfer in a directory named as the domain vulnerable in the following form: domain_axfr.log" 

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
```

License and Donations
-------

Written by Andrea 'cybernova' Dari and licensed under GNU GPL v2.0

If you have found this script useful I gladly accept donations, also symbolic through Paypal:

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=andreadari91%40gmail%2ecom&lc=IT&item_name=Andrea%20Dari%20IT%20independent%20researcher&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" alt="[paypal]" /></a> or Bitcoin: 1B2KqKm4CgzRfSsXv7VmbmXD9XNQzzLaTW
