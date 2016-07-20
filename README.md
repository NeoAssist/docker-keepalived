# docker-keepalived
---
## What is This?

A Dockerized Keepalived designed for simple high availability (HA) in multi-host container deployments. [Keepalived](http://www.keepalived.org/) provides failover for one or more Virtual IP addresses (VIPs) so they are always available, even if a host fails.

It has been designed specifically for use within [Rancher](http://rancher.com/) environments using HAProxy 'front ends', but should work with most types of multi-host container deployments that require HA and IP address failover for any kind of listening service (Apache, Nginx etc.).

## Services & Address Binding

HAProxy (and most other listening services) won't bind to an address that doesn't exist within the host's network stack. If any particular host  which .  This can cause a problem when the keepalived healthchecks run, as they look for the servie responding on the virtual ip.  In order to solve this, you can either configure HAProxy without an address (so it binds to all of them) with bind :80 for instance, or, the suggested use: enable HAProxy to bind to non-existent addresses by enabling the net.ipv4.ip_nonlocal_bind kernel setting.

Information on how to enable the kernel option:
- Debian/Ubuntu should work simply by
  adding "net.ipv4.ip_nonlocal_bind=1" to the end of the /etc/sysctl.conf file (no ") 
  running # sysctl -p (or sudo sysctl -p if you arent root)
- CoreOS should work simply by executing: 
  #/bin/sh -c "/usr/sbin/sysctl -w net.ipv4.ip_nonlocal_bind=1"   
  Another option is to add this to a unit file with a oneshot execution...
  
*Other distributions may have slightly different commands or syntax...google is your friend!*

**This is still a work in progress, constantly being changed and probably not ready, even for any real testing...**

# Thanks & Inspiration
This has come to be as a result of a discussion held on the Rancher Forums (https://forums.rancher.com/t/rancher-keepalived/1508/16).

Most if not all credit is due to Steven Iveson (@sjiveson ) - including the explanation above to enable nonlocal_bind. His scripts are at the heart of this.   Thanks also to @fabiorauber for bringing up the issue so we could improve the readme.
