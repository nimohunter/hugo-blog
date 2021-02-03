+++
author = "nimodai"
title = "build clean DNS service"
date = "2017-04-28"
description = ""
tags = [
    "DNS",
]
+++

As we know, every visit to google.com, the browser have to ask DNS server to get DNS infomation about google.com, but for some well-known reason, especially in China mainland, you will get a fake infomation. More seriouly, the ISP(Internet Service Provider)such as China Unicom or China Mobie, dirty the DNS, release ad in DNS infomarion.

So, we need a clean DNS service. unfortunately, the Google Public DNS : 8.8.8.8 , it's performance in China mainaland is unstable, but we have another method.

[DNS-over-HTTPS](https://developers.google.com/speed/public-dns/docs/dns-over-https) Which can use Https get DNS information.

Next, use the docker to configure it.

---
### 1. Pdnsd
We need this tools to cache DNS info,  docker image: [vimagick/pdnsd](https://hub.docker.com/r/vimagick/pdnsd/)

useage:

```
docker run --name mypdnsd -p 53:53/tcp -p 53:53/udp -d vimagick/pdnsd
```

then, docker-enter this, and edit `/etc/pdnsd.conf`

```
global {
        perm_cache=2048;
        cache_dir="/var/cache/pdnsd";
        run_as="pdnsd";
        server_ip = any;
        status_ctl = on;
#       paranoid=on;       # This option reduces the chance of cache poisoning
                           # but may make pdnsd less efficient, unfortunately.
        min_ttl=15m;       # Retain cached entries at least 15 minutes.
        max_ttl=1w;        # One week.
        timeout=10;        # Global timeout option (10 seconds).
        neg_domain_pol=on;
        query_method=tcp_only;

}

server {
        label = "prcdns";
        ip = 23.106.151.177;
        timeout = 10;
        port = 3535;
}

```

focus on `server {}` which is the transform, 

in general, you can use this:

```
server {
	label = "114dns"; 
	ip = 114.114.114.114,114.114.115.115;
	timeout = 10;
	port = 53; 
}
```

but in our method, we have to build a DNS server. 
ps. `23.106.151.177` is a test service.

### 2. Use DNS-over-HTTPS.
docker image: [lbp0200/PRCDNS](https://github.com/lbp0200/PRCDNS)

docker-enter this, see /run.sh

```
PRCDNS -l $HOST -p $PORT -r http_proxy
```

Because the DNS-over-Https website has been block, so you have to Shadowsocks to Http with polipo.

that's TODO. Have to configure the shadowsocks and polipo, then use this.