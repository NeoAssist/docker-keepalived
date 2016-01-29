# docker-keepalived
Dockerized keepalived to ease HA in deployments with multiple hosts.  Provides failover for Virtual IPs (VIP) to be always online even if a host fails.

It is being designed specifically for use with Rancher environments, but should probably work on most types of multi-machine deployments that require
HA and IP Failover.

**This is still a work in progress, constantly being changed and probably not ready, even for any real testing...**
