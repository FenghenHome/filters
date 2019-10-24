#!/bin/sh

# Author:   https://github.com/softwaredownload/openwrt-fanqiang
# Date:     2016-01-09

TMP_HOSTS=/tmp/block.hosts.unsorted
HOSTS=blockad.conf

# remove any old TMP_HOSTS that might have stuck around
rm ${TMP_HOSTS} 2> /dev/null
rm ${HOSTS} 2> /dev/null

for URL in \
    "https://raw.githubusercontent.com/vokins/yhosts/master/hosts" \
    "https://raw.githubusercontent.com/neoFelhz/neohosts/gh-pages/full/hosts" \
    "https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts"
do
    # filter out comment lines, empty lines, localhost... 
    # remove trailing comments, space( ,tab), empty line
    # replace line to dnsmasq format
    # remove carriage returns
    # append the results to TMP_HOSTS
    wget -4 --no-check-certificate -qO- "${URL}" | grep -v -e "^#" -e "^\s*$" -e "localhost" -e "broadcasthost" -e "ip6" -e "^;" -e "^@" -e "^:" -e "^[a-zA-Z]" \
    | sed -E -e "s/#.*$//" -e "s/[[:space:]]*//g" -e "/^$/d" \
    -e "s/^127.0.0.1/address=\//" -e "s/0.0.0.0/address=\//" -e "/^[0-9].*$/d" -e "s/$/\/127.0.0.1/" \
    | tr -d "\r" >> ${TMP_HOSTS}

done

# remove duplicate hosts and save the real hosts file
sort ${TMP_HOSTS} | uniq > ${HOSTS}

rm ${TMP_HOSTS} 2> /dev/null
