# docker-keepalived
Dockerized keepalived to ease HA in deployments with multiple hosts.  Provides failover for Virtual IPs (VIP) to be always online even if a host fails.

It is being designed specifically for use with Rancher environments, but should probably work on most types of multi-machine deployments that require
HA and IP Failover.

**This is still a work in progress, constantly being changed and probably not ready, even for any real testing...**

# Thanks & Inspiration
This has come to be as a result of a discussion held on the Rancher Forums (https://forums.rancher.com/t/rancher-keepalived/1508/16).

Most if not all credit is due to Steven Iveson (@itsthenetwork). His scripts are at the heart of this.
