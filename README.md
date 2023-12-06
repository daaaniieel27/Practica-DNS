# DNS sistema.sol # 

## INTRODUCTION ##

Before starting the practice, it is necessary to set the static ip addresses of the servers and install the bind9 service on both of them.

The objective of this practice is to create two machines that will act as DNS servers of an imaginary domain called "sistema.sol". We will use **Vagrant** to automate the task of creating and configuring the machines. 

The domain will consist of four servers (in my case the practice is finished with the ip's of tierra and venus swapped):

|        Servers          |       IP       |
|----------------------|----------------|
| mercurio.sistema.sol | 192.168.57.101 |
| tierra.sistema.sol    | 192.168.57.102 |
| venus.sistema.sol   | 192.168.57.103 |
| marte.sistema.sol    | 192.168.57.104 |

- **Tierra** will be the master nameserver, and will be authoritative of both zones, forward and reverse.
- **Venus** will be the slave nameserver.
- **Marte** will be the mail server.

## CONFIGURATION ## 

### NAMED CONFIGURATION ###

First, we will set earth and venus as default DNS servers.
To do this we edit the `/etc/resolv.conf` file on both servers.

```conf
nameserver 192.168.57.103
nameserver 192.168.57.102
```

#### named.conf.options config ####

*(All the configuration files of bind are located in `/etc/bind/`)* 

We start by editing the `named.conf.options` file. In this we will establish configurations such as, trusted networks, forwarders, activate or deactivate the recursion, etc.
Following the indications of the practice we establish the following options (in both servers):

```conf
acl confiables {
        192.168.57.0/24;
        127.0.0.0/8;
};

options {
        directory "/var/lib/bind";


        forwarders {
            208.67.222.222;
        };

        allow-transfer { 192.168.57.103; };
        listen-on port 53 { 192.168.57.102; };

        recursion yes;
        allow-recursion { confiables; };


        dnssec-validation yes;

        // listen-on-v6 { any; };
};
```
- Explanation of the chosen options:
    - `acl`: we configure our trusted networks.
    - `forwarders`: we set 208.67.222.222 for non-authoritative requests.
    - `allow-transfer { trusted; }`: we allow the transfer from our trusted network. This will allow the transfer of the zone between the master and the slave.
    - `recursion`: we allow the recursion from the trusted network.


#### named.conf.local ####

In this file we define the zones, here where we indicate where the files of each zone will be stored. In addition, we set the role of the server (master or slave). 

**Master:**

```conf
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "sistema.sol" {
        type master;
        file "/var/lib/bind/db.sistema.sol";
};

zone "57.168.192.in-addr.arpa" {
        type master;
        file "/var/lib/bind/sistema.sol.rev";
};
```

**Slave:**

```conf
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "sistema.sol" {
        type slave;
        file "/var/lib/bind/db.sistema.sol";
        masters {
                 192.168.57.102;
        };
};

zone "57.168.192.in-addr.arpa" {
        type slave;
        file "/var/lib/bind/sistema.sol.rev";
        masters {
                 192.168.57.102;
        };
};
```

Now we can restart the named service to apply the changes.

* (To test that the configuration is correct we can use the command: `# named-checkconf [file]` for config files, and `# named-checkzone [zone] [file]` for zone files)


### ZONES CONFIGURATION ###

#### FORWARD ZONE (/var/lib/bind/db.sistema.sol) ####

As indicated in the `named.conf.local` file, we will store the zone configuration file in `/var/lib/bind/db.system.sol`. *(we can use the file `/etc/bind/db.empty` to copy it as a template)*.

To follow the indications of the practice, the file should look like this: 

```conf;
; sistema.sol
;
$TTL    86400
@       IN      SOA         tierra.sistema.sol.     root.sistema.sol. (
                                    1              ;    Serial
                                    3600           ;    Refresh
                                    1800           ;    Retry
                                    604800         ;    Expire    
                                    86400)         ;    Negative Cache TTL
;

@       IN      NS          tierra.sistema.sol.
tierra.sistema.sol.         IN      A       192.168.57.102
venus.sistema.sol.          IN      A       192.168.57.103
marte.sistema.sol.          IN      A       192.168.57.104
ns1     IN      CNAME       tierra.sistema.sol.
ns2     IN      CNAME       venus.sistema.sol.
mail.sistema.sol.           IN      CNAME   marte.sistema.sol.
@       IN      MX 10       marte.sistema.sol.
```
*(we used absolute paths in this case)*

- Set negative cache TTL to 2h (7200s)
- Set tierra and venus as the domain name servers
- Set marte as the domain mail server with a priority of 10
- Set the corresponding aliases to name servers and mail server

#### REVERSE ZONE (/var/lib/bind/sistema.sol.rev) ####

```conf
;
; 57.168.192
$TTL    86400
@       IN      SOA     tierra.sistema.sol. admin.deaw.es. (
                                1       ;   Serial
                                3600    ;   Refresh
                                1800    ;   Retry
                                604800  ;   Expire
                                86400 )  ;   Negative Cache TTL
;
@       IN      NS      tierra.sistema.sol.
102     IN      PTR     tierra.sistema.sol.
103     IN      PTR     venus.sistema.sol.
104     IN      PTR     marte.sistema.sol.
```
*(we used relative paths in this case)*

- Set negative cache TTL to 2h (7200s)
- Set the name servers (tierra and venus)
- Set the corresponding IP to name translations
  
#### CHECKS ####
Once we have finished the practice we check it using the dig command:

```
dani@debian:~$ dig tierra.sistema.sol

; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> tierra.sistema.sol
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 8216
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 441fa9f0b50e830901000000655f4b79e6142d71c74771ba (good)
;; QUESTION SECTION:
;tierra.sistema.sol.            IN      A

;; ANSWER SECTION:
tierra.sistema.sol.     86400   IN      A       192.168.57.102

;; Query time: 0 msec
;; SERVER: 192.168.57.103#53(192.168.57.103) (UDP)
;; WHEN: Thu Nov 23 13:54:17 CET 2023
;; MSG SIZE  rcvd: 91

```
```
dani@debian:~$ dig venus.sistema.sol

; <<>> DiG 9.18.19-1~deb12u1-Debian <<>> venus.sistema.sol
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18489
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 6eb65bb078f92e4301000000655f4c0a7f8d5e9bfd8bf0f7 (good)
;; QUESTION SECTION:
;venus.sistema.sol.             IN      A

;; ANSWER SECTION:
venus.sistema.sol.      86400   IN      A       192.168.57.103

;; Query time: 0 msec
;; SERVER: 192.168.57.103#53(192.168.57.103) (UDP)
;; WHEN: Thu Nov 23 13:56:42 CET 2023
;; MSG SIZE  rcvd: 90

```

You can also check it by using the dig command using the ips, ns1and ns2, mx, etc. 
