#!/bin/bash
URL="https://account.protonvpn.com/api/vpn/config?APIVersion=3&Category=Server&Platform=iOS&Protocol=udp&Tier=2"
TPL="template"
TMP="tmp"
SERVERS_SRC="$TPL/servers.zip"
SERVERS_DST="$TPL/servers.csv"
SAMPLE_CFG="$TMP/at-01.protonvpn.com.udp.ovpn"
CA="$TPL/ca.crt"
TLS_KEY="$TPL/ta.key"

LINES=100000
CA_BEGIN="<ca>"
CA_END="</ca>"
TLS_BEGIN="<tls-auth>"
TLS_END="</tls-auth>"
ID_REGEX="([a-z]+)(-free)?(-[a-z]+)?-([0-9]+)"
#ID_REGEX="([a-z]+)(-[a-z]+)?-([0-9]+)"

# TODO: parse Tor support?

mkdir -p $TPL
curl -L $URL >$SERVERS_SRC
rm -rf $TMP
unzip $SERVERS_SRC -d $TMP

grep -A$LINES $CA_BEGIN $SAMPLE_CFG | grep -B$LINES $CA_END | egrep -v "$CA_BEGIN|$CA_END" >$CA
grep -A$LINES $TLS_BEGIN $SAMPLE_CFG | grep -B$LINES $TLS_END | egrep -v "$TLS_BEGIN|$TLS_END" >$TLS_KEY

rm -f $SERVERS_DST
for CFG in `cd $TMP && ls *.ovpn`; do
    #fr-09.protonvpn.com.udp.ovpn
    HOST=`echo $CFG | sed -E "s/(.+)\.udp\.ovpn$/\1/"`
    HOST_COMPS=(${HOST//./ })
    ID=${HOST_COMPS[0]}
    if [[ $ID =~ $ID_REGEX ]]; then
        COUNTRY=${BASH_REMATCH[1]}
        [ "${BASH_REMATCH[2]}" = "-free" ] && FREE=1 || FREE=0
        AREA=${BASH_REMATCH[3]:1}
        SERVER_NUM=${BASH_REMATCH[4]}
        echo $ID,$COUNTRY,$AREA,$SERVER_NUM,$FREE,$HOST >>$SERVERS_DST
    fi
done
sed -i"" -E "s/,uk,/,gb,/g" $SERVERS_DST
