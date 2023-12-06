# DNS sistema.sol # 

## INTRODUCTION ##

The objective of this practice is to create two machines that will act as DNS servers of a imaginary domain called "sistema.sol". We will use **Vagrant** to automatize the task of creating and configuring the machines. 

The domain will consists of four servers:

|        FQDN          |       IP       |
|----------------------|----------------|
| mercurio.sistema.sol | 192.168.57.101 |
| venus.sistema.sol    | 192.168.57.102 |
| tierra.sistema.sol   | 192.168.57.103 |
| marte.sistema.sol    | 192.168.57.104 |

- **Tierra** will be the master nameserver, and will be authoritative of both zones, forward and reverse.
- **Venus** will be the slave nameserver.
- **Marte** will be the mail server.

## CONFIGURATION ## 

### NAMED CONFIGURATION ###

First, we will set tierra and venus as the default DNS servers (it will be useful to test the configuration later). 
We just edit the file `/etc/resolv.conf` in both servers.

```conf
nameserver 192.168.57.103
nameserver 192.168.57.102
```

#### named.conf.options config ####

*(All the configuration files of bind are located in `/etc/bind/`)* 

We will begin editing the file `named.conf.options`. In this file we will set settings such as, trusted networks, external forwarders, enable or disable recursion, etc.
To comply with the objectives of the task we will set the following options (in both servers):

```conf
acl trusted {

	127.0.0.0/8;
	192.168.57.0/24;
};

options {
	directory "/var/cache/bind";

	forwarders {
	 	208.67.222.222;
	 };
	
	forward only;

	allow-transfer { trusted; };
	
	listen-on port 53 { 192.168.57.X; };
	
	recursion yes;
	allow-recursion { trusted; };

	dnssec-validation yes;

	// listen-on-v6 { any; };
};
```
* (X should be replaced with the IP of the server)

- Explanation of the choosen options:
    - `acl`: here we set our trusted networks.
    - `forwarders`: we set 208.67.222.222 for non-authoritative requests.
    - `allow-transfer { trusted; }`: we allow transfer from our trusted network. This will allow the transfer of the zone between the master and the slave.
    - `recursion`: allow recursion from trusted network.

#### named.conf.local ####

In this file is where the zones are defined, so it is here where we will indicate where the files of each zone will be stored. Also, we need to set the role of the server (master or slave). The configuration of the file will be sligthy different between master and slave in this case.

**Master:**

```conf
zone "sistema.sol" {
	type master;
	file "/var/lib/bind/sistema.sol.dns";
};

zone "57.168.192.in-addr.arpa" {
	type master;
	file "/var/lib/bind/sistema.sol.rev";
};
```

**Slave:**

```conf
zone "sistema.sol" {
	type slave;
	masters { 192.168.57.103; };
	file "/var/lib/bind/sistema.sol.dns";
};

zone "57.168.192.in-addr.arpa" {
	type slave;
	masters { 192.168.57.103; };
	file "/var/lib/bind/sistema.sol.rev";
};
```

Now we can restart the named service to apply the changes.

* (we can test the configuration with the command: `# named-checkconf [file]` for config files, and `# named-checkzone [zone] [file]` for zone files)

### ZONES CONFIGURATION ###

#### FORWARD ZONE (/var/lib/bind/sistema.sol.dns) ####

As we indicated in the file `named.conf.local`, we will store the zone config file at `/var/lib/bind/sistema.sol.dns`. *(we can use the file `/etc/bind/db.empty` as a template)* 

To accomplish the tasks' objectives, the file should look like this: 

```conf
;
; zone: sistema.sol.
;

$TTL	86400
@	IN	SOA	tierra.sistema.sol. admin.sistema.sol. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  7200 )	; Negative Cache TTL
;

; RESOLVE RECORDS (RR)
; name servers (NS)
@			IN	NS	tierra.sistema.sol.
@			IN	NS	venus.sistema.sol.

; host addresses (A)
tierra.sistema.sol.	IN	A	192.168.57.103
mercurio.sistema.sol.	IN	A	192.168.57.101
venus.sistema.sol.	IN	A	192.168.57.102
marte.sistema.sol.	IN	A	192.168.57.104

; mail servers (MX)
sistema.sol.		IN	MX 10	marte.sistema.sol.

; aliases
ns1.sistema.sol.	IN	CNAME	tierra.sistema.sol.
ns2.sistema.sol.	IN	CNAME	venus.sistema.sol.
mail.sistema.sol.	IN	CNAME	marte.sistema.sol.
```
*(we used absolute paths in this case)*

- Set negative cache TTL to 2h (7200s)
- Set tierra and venus as the domain name servers
- Set marte as the domain mail server with a priority of 10
- Set the corresponding aliases to name servers and mail server

#### REVERSE ZONE (/var/lib/bind/sistema.sol.rev) ####

```conf
;
; zone: 57.168.192.in-addr.arpa
;

$TTL	86400
@	IN	SOA	tierra.sistema.sol. admin.sistema.sol. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  7200 )	; Negative Cache TTL
;


; RESOLVE RECORDS (RR)
; name servers (NS)
@			IN	NS	tierra.sistema.sol.
@			IN	NS	venus.sistema.sol.

; reverse host resolution
103			IN	PTR	tierra.sistema.sol.
101			IN	PTR	mercurio.sistema.sol.
102			IN	PTR	venus.sistema.sol.
104			IN	PTR	marte.sistema.sol.
```
*(we used relative paths in this case)*

- Set negative cache TTL to 2h (7200s)
- Set the name servers (tierra and venus)
- Set the corresponding IP to name translations
  
