#!/bin/bash
rm -rf rules
cnlist() {
    wget -4 -O dnsmasq.accelerated-domains.conf https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf
    wget -4 -O dnsmasq.bogus-nxdomain.conf https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/bogus-nxdomain.china.conf
    wget -4 -O dnsmasq.bogus-nxdomain.ext.conf https://raw.githubusercontent.com/vokins/yhosts/master/dnsmasq/ip.conf
    wget -4 -O apple.china.conf https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf

    sed -i "s/114.114.114.114/119.29.29.29/g" *.conf

    # dnsmasq.bogus-nxdomain.conf
    cat dnsmasq.bogus-nxdomain.conf dnsmasq.bogus-nxdomain.ext.conf > file.txt
    rm -rf dnsmasq.bogus-nxdomain.ext.conf dnsmasq.bogus-nxdomain.conf
    awk '!x[$0]++' file.txt > dnsmasq.bogus-nxdomain.conf
    rm -rf file.txt
    sort -n dnsmasq.bogus-nxdomain.conf | uniq > file.txt
    sort -n file.txt | awk '{if($0!=line)print; line=$0}' > tmp.txt
    sort -n tmp.txt | sed '$!N; /^\(.*\)\n\1$/!P; D' | sed '/#/d' > dnsmasq.bogus-nxdomain.conf
    rm -rf file.txt tmp.txt

    # dnsmasq.accelerated-domains.conf
    cat dnsmasq.accelerated-domains.conf apple.china.conf > file.txt
    rm -rf apple.china.conf dnsmasq.accelerated-domains.conf
    awk '!x[$0]++' file.txt > dnsmasq.accelerated-domains.conf
    rm -rf file.txt
    sort -n dnsmasq.accelerated-domains.conf | uniq > file.txt
    sort -n file.txt | awk '{if($0!=line)print; line=$0}' > tmp.txt
    sort -n tmp.txt | tr -s '\n' | tr A-Z a-z | sed '$!N; /^\(.*\)\n\1$/!P; D' | grep -v '[#].*\/' > dnsmasq.accelerated-domains.conf
    rm -rf file.txt tmp.txt
}

cnlist_overture() {
    cat dnsmasq.accelerated-domains.conf | sed 's/server=\///g; s/\/119.29.29.29//g' > overture.accelerated-domains.conf
}

cnlist_unbound() {
    cat overture.accelerated-domains.conf | sed -e 's|\(.*\)|forward-zone:\n  name: "\1."\n  forward-addr: 8.8.8.8@853\n  forward-tls-upstream: yes\n|' > unbound.accelerated-domains.conf
}

cnlist_dnscrypt() {
    cat dnsmasq.accelerated-domains.conf | grep -v '^#server' | sed -e 's|/| |g' -e 's|^server= ||' >dnscrypt-forwarding-rules.conf
}

adblock() {
    wget -4 -O - https://raw.githubusercontent.com/FenghenHome/adguard-home-filters/gh-pages/filters.txt |
    grep ^\|\|[^\*]*\^$ |
    sed -e 's:||:address\=\/:' -e 's:\^:/0\.0\.0\.0:' | uniq > dnsmasq.adblock-domains.conf

    wget -4 -O - https://raw.githubusercontent.com/vokins/yhosts/master/dnsmasq/union.conf |
    sed -e 's/address\=\/\./address\=\//g; s/address\=\/\./address\=\//g; /#/d' > union.conf

    wget -4 -O - http://iytc.net/tools/ad.conf |
    sed -e 's/127.0.0.1/0.0.0.0/g; s/address\=\/\./address\=\//g; s/address\=\/\./address\=\//g; /#/d' > ad.conf

    # dnsmasq.adblock-domains.conf
    cat dnsmasq.adblock-domains.conf union.conf > file.txt
    rm -rf dnsmasq.adblock-domains.conf union.conf
    awk '!x[$0]++' file.txt > dnsmasq.adblock-domains.conf
    rm -rf file.txt
    cat dnsmasq.adblock-domains.conf ad.conf > file.txt
    rm -rf dnsmasq.adblock-domains.conf ad.conf
    awk '!x[$0]++' file.txt > dnsmasq.adblock-domains.conf
    rm -rf file.txt
    cat dnsmasq.adblock-domains.conf myblock.conf > file.txt
    rm -rf dnsmasq.adblock-domains.conf
    awk '!x[$0]++' file.txt > dnsmasq.adblock-domains.conf
    rm -rf file.txt
    sort -n dnsmasq.adblock-domains.conf | uniq > file.txt
    sort -n file.txt | awk '{if($0!=line)print; line=$0}' > tmp.txt
    sort -n tmp.txt | tr -s '\n' | tr A-Z a-z | sed '$!N; /^\(.*\)\n\1$/!P; D' | sed 's/\.\//\//g' | grep -v '[#].*\/' | grep '[.].*\/' > dnsmasq.adblock-domains.conf
    sed -i "/\/m\.baidu\.com\/0/d" dnsmasq.adblock-domains.conf
    rm -rf file.txt tmp.txt
    cat dnsmasq.adblock-domains.conf | sed 's/address/server/g; s/0\.0\.0\.0//g' > dnsmasq.adblock-domains.nxdomain.conf
}

adblock_overture() {
    cat dnsmasq.adblock-domains.conf | sed 's/address=\///g; s/\/0\.0\.0\.0//g' | grep -E -v '([^0-9]|\b)((1[0-9]{2}|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])\.){3}(1[0-9][0-9]|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])([^0-9]|\b)' | sed -e 's|\(.*\)|0.0.0.0 *.\1|' > overture.adblock-domains.conf
    cat dnsmasq.adblock-domains.conf | sed 's/address=\///g; s/\/0\.0\.0\.0//g' | grep -E -v '([^0-9]|\b)((1[0-9]{2}|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])\.){3}(1[0-9][0-9]|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])([^0-9]|\b)' | sed -e 's|\(.*\)|:: *.\1|' >> overture.adblock-domains.conf
}

adblock_unbound() {
    cat dnsmasq.adblock-domains.conf | sed 's/address=\///g; s/\/0\.0\.0\.0//g' | grep -E -v '([^0-9]|\b)((1[0-9]{2}|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])\.){3}(1[0-9][0-9]|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])([^0-9]|\b)' | sed -e 's|\(.*\)|local-zone: "\1." redirect\nlocal-data: "\1. A 0.0.0.0"\nlocal-data: "\1. AAAA ::"\n|' > unbound.adblock-domains.conf
    cat dnsmasq.adblock-domains.conf | sed 's/address=\///g; s/\/0\.0\.0\.0//g' | grep -E -v '([^0-9]|\b)((1[0-9]{2}|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])\.){3}(1[0-9][0-9]|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])([^0-9]|\b)' | sed -e 's|\(.*\)|local-zone: "\1." static\n|' > unbound.adblock-domains.nxdomain.conf
}

adblock_dnscrypt() {
    cat dnsmasq.adblock-domains.conf | sed 's/address=\///g; s/\/0\.0\.0\.0//g' | grep -E -v '([^0-9]|\b)((1[0-9]{2}|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])\.){3}(1[0-9][0-9]|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])([^0-9]|\b)' > toblock-without-shorturl-optimized.lst
    echo 'ad.*' >>dnscrypt-blacklist-domains.conf
    echo 'ad[0-9]*' >>dnscrypt-blacklist-domains.conf
    echo 'ads.*' >>dnscrypt-blacklist-domains.conf
    echo 'ads[0-9]*' >>dnscrypt-blacklist-domains.conf
    cat toblock-without-shorturl-optimized.lst | grep -v '^ad\.' | grep -v -e '^ad[0-9]' | grep -v '^ads\.' | grep -v -e '^ads[0-9]' | rev | sort -n | uniq | rev >>dnscrypt-blacklist-domains.conf
    rm toblock-without-shorturl-optimized.lst
}

chinalist_ips() {
    wget -4 -O ignore-ips.china.conf https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
}

blacklist_ips_dnscrypt() {
    cat dnsmasq.bogus-nxdomain.conf | grep -v '^#bogus' | grep bogus-nxdomain | sed 's/bogus-nxdomain=//g' > dnscrypt-blacklist-ips.conf
    cat dnsmasq.adblock-domains.conf | sed 's/address=\///g; s/\/0\.0\.0\.0//g' | grep -E '([^0-9]|\b)((1[0-9]{2}|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])\.){3}(1[0-9][0-9]|2[0-4][0-9]|25[0-5]|[1-9][0-9]|[0-9])([^0-9]|\b)' >> dnscrypt-blacklist-ips.conf
    sort -n dnscrypt-blacklist-ips.conf | uniq > file.txt
    sort -n file.txt | awk '{if($0!=line)print; line=$0}'> tmp.txt
    sort -n tmp.txt | sed '$!N; /^\(.*\)\n\1$/!P; D'> dnscrypt-blacklist-ips.conf
    rm file.txt tmp.txt
}

gfwlist() {
    # wget -4 -O dnsmasq.gfw-domains.conf https://cokebar.github.io/gfwlist2dnsmasq/dnsmasq_gfwlist_ipset.conf
    # wget -4 -O dnsmasq.gfw-domains.conf https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/gh-pages/dnsmasq_gfwlist_ipset.conf
    wget -4 -O gfwlist2dnsmasq.sh https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/master/gfwlist2dnsmasq.sh && chmod +x gfwlist2dnsmasq.sh && bash gfwlist2dnsmasq.sh -p 5335 -s gfwlist -o dnsmasq.gfw-domains.tmp.conf
    cat dnsmasq.gfw-domains.tmp.conf | sed -i '/^#/d;/^$/d' | tr -s '\n' | tr A-Z a-z | grep -v '[#].*\/' > dnsmasq.gfw-domains.conf
    rm -rf gfwlist2dnsmasq.sh dnsmasq.gfw-domains.tmp.conf
}

gfwlist_overture() {
    cat dnsmasq.gfw-domains.conf | sed 's/ipset=\///g; s/\/gfwlist//g; /^server/d; /#/d' > overture.gfw-domains.conf
}

gfwlist_unbound() {
    cat overture.gfw-domains.conf | sed -e 's|\(.*\)|forward-zone:\n  name: "\1."\n  forward-addr: 8.8.8.8@853\n  forward-tls-upstream: yes\n|' > unbound.gfw-domains.conf
}

gfwlist_dnscrypt() {
    wget -4 -O dnscrypt-cloaking-rules.conf https://raw.githubusercontent.com/googlehosts/hosts/master/hosts-files/dnscrypt-proxy-cloaking.txt
}

gfwlist_adguardhome() {
    cat overture.gfw-domains.conf | sed -e 's|\(.*\)|[/\1/]8.8.8.8:53|' > adguardhome.gfw-domains.conf
}

netflix() {
    wget -4 -O - https://raw.githubusercontent.com/ab77/netflix-proxy/master/proxy-domains.txt | sed -e 's|\(.*\)|server=/\1/127.0.0.1#5335\nipset=/\1/gfwlist|' | tr -s '\n' | tr A-Z a-z | grep -v '[#].*\/' > dnsmasq.netflix-domains.conf
}

complete() {
    mkdir rules
    mv dnsmasq.accelerated-domains.conf dnsmasq.bogus-nxdomain.conf dnsmasq.adblock-domains.conf dnsmasq.adblock-domains.nxdomain.conf ignore-ips.china.conf dnsmasq.gfw-domains.conf unbound.gfw-domains.conf overture.gfw-domains.conf overture.accelerated-domains.conf unbound.accelerated-domains.conf dnscrypt-blacklist-ips.conf dnscrypt-blacklist-domains.conf dnscrypt-cloaking-rules.conf dnscrypt-forwarding-rules.conf unbound.adblock-domains.conf unbound.adblock-domains.nxdomain.conf overture.adblock-domains.conf dnsmasq.netflix-domains.conf adguardhome.gfw-domains.conf rules
}

cnlist
cnlist_overture
cnlist_unbound
cnlist_dnscrypt
adblock
adblock_overture
adblock_unbound
adblock_dnscrypt
chinalist_ips
blacklist_ips_dnscrypt
gfwlist
gfwlist_overture
gfwlist_unbound
gfwlist_dnscrypt
gfwlist_adguardhome
netflix
complete
