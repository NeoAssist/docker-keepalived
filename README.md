# docker-keepalived
---
## Purpose

A Dockerized Keepalived designed for simple high availability (HA) in multi-host container deployments. [Keepalived](http://www.keepalived.org/) provides failover for one or more Virtual IP addresses (VIPs) so they are always available, even if a host fails.

It has been designed specifically for use within [Rancher](http://rancher.com/) environments using HAProxy 'front ends', but should work with most types of multi-host container deployments that require HA and IP address failover for any kind of listening service (Apache, Nginx etc.).

## Services & Address Binding

HAProxy (and most other listening services) won't bind to an address that doesn't exist within the host's network stack. As Keepalived will only host any particular VIP on a single host, the service(s) on the remaining ones will not be able to bind to the VIP address and will likely fail. Keepalived on those hosts will also fail as it is performing a health check on the service itself (by checking for a listener on the VIP address and the service port you specify).

In order to avoid this issue, you can either;

- Configure HAProxy (or whatever service you are using) without an address (so it binds to all of them) with, for example;
 - `bind :80`
 - `bind *:80`
 - `bind 0.0.0.0:80`

- Enable binding to non-existent addresses by setting the `net.ipv4.ip_nonlocal_bind` kernel parameter to 1

### Enabling Non-local Binding - Most Distros

On Debian, RHEL & most Linux variants simply add `net.ipv4.ip_nonlocal_bind=1` to the end of the **/etc/sysctl.conf** file and force a reload of the file with the `[sudo] sysctl -p` command

### Enabling Non-local Binding - RancherOS v0.5.0 and later

Edit the **/var/lib/rancher/conf/cloud-config.d/user_config.yml** file and add this in an appropriate place:
```
rancher:
  sysctl:
    net.ipv4.ip_nonlocal_bind: 1
```

### Enabling Non-local Binding - RancherOS v0.4.5 and earlier

If your not using the default console, see the prior section for Most Distros. If you are read on.

If you don't already have a **/opt/rancher/bin/start.sh** startup file, edit the **/var/lib/rancher/conf/cloud-config.d/user_config.yml** file and add this to it to create a suitable file which will run the `sysctl -p` command:
```
write_files:
  - encoding: b64
    content: IyEvYmluL3NoCnN5c2N0bCAtcApleGl0Cg==
    owner: root:root
    path: /opt/rancher/bin/start.sh
    permissions: '0744'
```
If you do already have this file, add the `sysctl -p` command to it.

In either case, add this to the end of the **/var/lib/rancher/conf/cloud-config.d/user_config.yml** file to create a suitable **/etc/sysctl.conf** file:
```
write_files:
  - encoding: b64
    content: bmV0LmlwdjQuY29uZi5hbGwuYXJwX2FjY2VwdCA9IDEgCm5ldC5pcHY0LmlwX25vbmxvY2FsX2JpbmQgPSAxIApuZXQuaXB2NC5jb25mLmFsbC5wcm9tb3RlX3NlY29uZGFyaWVzID0gMQo=
    owner: root:root
    path: /etc/sysctl.conf
    permissions: '0644'
```
Reboot to have the files written and executed.

### Enabling Non-local Binding - CoreOS

Use this command: `#/bin/sh -c "/usr/sbin/sysctl -w net.ipv4.ip_nonlocal_bind=1` or add this to a unit file with a oneshot execution.

*Other distributions may have slightly different commands or syntax...google is your friend!*

**This is still a work in progress, constantly being changed and probably not ready, even for any real testing...**

## Health Checks

If you'd like the health check to only check for something listening on a specified port, rather than an address and port, only set the CHECK_PORT variable, not the CHECK_IP variable.

If you do want to check the address and port combination, set the CHECK_IP variable to the same value as the VIRTUAL_IP variable.

If you want to use your own custom script, set the CHECK_SCRIPT variable.

If using a custom script, note that due to the way Rancher works, you cannot perform a port check for another Rancher service which has a port mapped/bound to/from the host. This won't show up in the output of the `ss` or `netstat` commands. To overcome this;
- Switch to a different kind of monitor, such as a HTTP check.
- Configure the other service to use host mode.

If you plan on using some other kind of health check which relies on the ability to use DNS names to connect to another Rancher service, ensure you add the `io.rancher.container.dns` label to this service's compose definition and set it's value to `'true'`.

## Status Checking

You can check the status of Keepalived by opening an interactive shell in the container and typing `status`. This is an alias for `pidof keepalived | kill -s USR1; cat /tmp/keepalived.data`. As you can surmise, sending the USR1 signal to the keepalived process causes it to write a status file to **/tmp/keepalived**.

You can also confirm Keepalived is running on any particular host by confirming a process is listening on protocol number 112 with command `ss -lwn`. You can confirm that process is keepalived with `sudo ss -lwnp`.

## Using the Docker Run Command

If you'd like to quickly test the built image at the CLI using the `docker run` command, something like this will work:

```
docker run -d --privileged --net host --name keepalived -e VIRTUAL_IP=10.11.12.99 -e CHECK_PORT=443 -e VIRTUAL_MASK=24 -e VRID=99 -e INTERFACE=eht0 docker-keepalived
```

## Thanks & Inspiration

This has come to be as a result of a discussion held on the Rancher Forums (https://forums.rancher.com/t/rancher-keepalived/1508/16).

Most if not all credit is due to Steven Iveson (@sjiveson ) - including the explanation above to enable nonlocal_bind. His scripts are at the heart of this.   Thanks also to @fabiorauber for bringing up the issue so we could improve the readme.
