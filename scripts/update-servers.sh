#!/bin/bash
URL="https://account.protonvpn.com/api/vpn/config?APIVersion=3&Platform=iOS&Protocol=udp&Tier=2"
URL_PREMIUM="${URL}&Category=Server"
URL_SECURECORE="${URL}&Category=SecureCore"
URLS=($URL_PREMIUM $URL_SECURECORE)
PLANS=("p" "sc")

TPL="template"
TMP="tmp"
SERVERS_SRC="$TPL/servers.zip"
SERVERS_DST="$TPL/servers.csv"
SAMPLE_CFG="$TMP/p/at-01.protonvpn.com.udp.ovpn"
CA="$TPL/ca.crt"
TLS_KEY="$TPL/ta.key"

LINES=100000
CA_BEGIN="<ca>"
CA_END="</ca>"
TLS_BEGIN="<tls-auth>"
TLS_END="</tls-auth>"
ID_REGEX="([a-z]+)(-free)?(-[a-z]+)?-([0-9]+)"
#ID_REGEX="([a-z]+)(-[a-z]+)?-([0-9]+)"

# TODO: parse Tor support, grep "tor" in filename

mkdir -p $TPL
rm -rf $TMP
mkdir $TMP

rm -f $SERVERS_DST
for I in ${!PLANS[@]}; do
    URL=${URLS[$I]}
    PLAN=${PLANS[$I]}
    SUB="$TMP/$PLAN"

    if ! curl -L $URL >$SERVERS_SRC.$PLAN; then
        exit
    fi
    unzip $SERVERS_SRC.$PLAN -d $TMP/$PLAN

    for CFG in `cd $SUB && ls *.ovpn`; do
        #fr-09.protonvpn.com.udp.ovpn
        HOST=`echo $CFG | sed -E "s/(.+)\.udp\.ovpn$/\1/"`
        HOST_COMPS=(${HOST//./ })
        ID=${HOST_COMPS[0]}
        ADDRS_LIST=(`grep -E "remote ([0-9\.]+)" $SUB/$CFG | sed -E "s/^.*remote (([0-9]+\.){3}[0-9]+).*$/\1/g" | uniq`)
        ADDRS=$(printf ":%s" "${ADDRS_LIST[@]}")
        ADDRS=${ADDRS:1}

        if [[ $ID =~ $ID_REGEX ]]; then
            COUNTRY=${BASH_REMATCH[1]}
            [ "${BASH_REMATCH[2]}" = "-free" ] && FREE=1 || FREE=0
            AREA=${BASH_REMATCH[3]:1}
            SERVER_NUM=${BASH_REMATCH[4]}

            if [[ $PLAN = "sc" ]]; then
                HOST=""
            fi
            echo $ID,$COUNTRY,$AREA,$SERVER_NUM,$FREE,$HOST,$ADDRS >>$SERVERS_DST
        fi
    done
done
sed -i"" -E "s/,uk,/,gb,/g" $SERVERS_DST

grep -A$LINES $CA_BEGIN $SAMPLE_CFG | grep -B$LINES $CA_END | egrep -v "$CA_BEGIN|$CA_END" >$CA
grep -A$LINES $TLS_BEGIN $SAMPLE_CFG | grep -B$LINES $TLS_END | egrep -v "$TLS_BEGIN|$TLS_END" >$TLS_KEY
