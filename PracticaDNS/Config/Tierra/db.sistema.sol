;
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