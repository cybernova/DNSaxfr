DNSaxfr
====

Shell script for testing DNS AXFR vulnerability.

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
./DNSaxfr.sh [OPTION...][SITE...]

```
* **0 Arguments and Options:**

The script acts like a filter, reads from stdin and writes on stdout, useful for using it in a pipeline.
**NOTE:** It takes one domain to test per line

* **1+ Arguments:**

The script tests every domain specified as argument, writing the output on stdout.

***Options:***

```
-i - Interactive mode

```

## Tested Environments

* GNU/Linux

If you have successfully tested this script on others systems or platforms please let me know.

License and Donations
-------

Written by Andrea 'cybernova' Dari and licensed under GNU GPL v2.0

If you have found this script useful I gladly accept donations, also symbolic through Paypal:

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=andreadari91%40gmail%2ecom&lc=IT&item_name=Andrea%20Dari%20IT%20independent%20researcher&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" alt="[paypal]" /></a> or Bitcoin: 1B2KqKm4CgzRfSsXv7VmbmXD9XNQzzLaTW
