# docker-keepalived
Dockerized keepalived to ease HA in deployments with multiple hosts.  Provides failover for Virtual IPs (VIP) to be always online even if a host fails.

It is being designed specifically for use with Rancher environments, but should probably work on most types of multi-machine deployments that require
HA and IP Failover.

# Some "gotchas" for correct usage

HAProxy (and most other services) won't bind to an address that doesn't exist.  This can cause a problem when the keepalived healthchecks run, as they look for the servie responding on the virtual ip.  In order to solve this, you can either configure HAProxy without an address (so it binds to all of them) with bind :80 for instance, or, the suggested use: enable HAProxy to bind to non-existent addresses by enabling the net.ipv4.ip_nonlocal_bind kernel setting.

Information on how to enable the kernel option:
Debian/Ubuntu should work simply by adding "" to the end of the /etc/sysctl.conf file (no ") and running # sysctl -p
CoreOS should work simply by executing: #/bin/sh -c "/usr/sbin/sysctl -w net.ipv4.ip_nonlocal_bind=1"   
  Another option is to add this to a unit file with a oneshot execution...
  
*Other distributions may have slightly different commands or syntax...google is your friend!*

**This is still a work in progress, constantly being changed and probably not ready, even for any real testing...**

# Thanks & Inspiration
This has come to be as a result of a discussion held on the Rancher Forums (https://forums.rancher.com/t/rancher-keepalived/1508/16).

Most if not all credit is due to Steven Iveson (@sjiveson ) - including the explanation above to enable nonlocal_bind. His scripts are at the heart of this.   Thanks also to @fabiorauber for bringing up the issue so we could improve the readme.
