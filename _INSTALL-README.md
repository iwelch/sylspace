---
title: SylSpace Installation
author: Ivo Welch
date: Oct 20, 2019
---



## Installation

All necessary apt and perl packages are installed as follows:

```
sudo sh initsylspaceinstall.sh  ## install apt/cpan
perl initsylspace.pm		## check cpan modules 
```

Next comes the real preparationof SylSpace:

```
# perl initsylspace.pl
```

This will create `/var/` etc and create a secret.  At the end it suggests the following:

```
cd Model
perl mkstartersite.t  ## creates a corpfin site, adds some info for ivo welch, etc.
perl addside.pl somesite yourname@gmail.com
```

If your domainname is fake (such as `syllabus.test`), then the following will fix up your /etc/hosts file:

```
sudo wildcardhost.pl syllabus.test
```


### Startup

You can now run the app either via

```
hypnotoad SylSpace
morbo -l 'http://[::]:80' SylSpace
morbo -m development -l 'http://*:80' SylSpace ## more verbose errors and logs, dangerous if leaked to ourside
morbo -m production  -l 'http://*:80' SylSpace ## don't leak on error
SylSpace daemon -m development
```


## Cleanup

* you can erase/fix up log/production.log and log/development.log.

