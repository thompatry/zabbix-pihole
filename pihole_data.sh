#!/usr/bin/env bash

set -e

pihole_server=localhost

CACHE_FILE=/var/log/zabbix/pihole-data.log
LOCK_FILE=/tmp/pihole-data.lock

run_pihole_query() {
    cd "$(readlink -f "$(dirname "$0")")" || exit 9

    # Lock
    if [[ -e "$LOCK_FILE" ]]
    then
        echo "Already getting data from pihole" >&2
        exit 2
    fi
    touch "$LOCK_FILE"
    trap "rm -rf $LOCK_FILE" EXIT HUP INT QUIT PIPE TERM

    local domains_blocked dns_queries_today ads_blocked_today ads_percentage_today

    get_domainsblocked(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.domains_being_blocked')
        domains_blocked=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
    }
    get_dnsqueriestoday(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.dns_queries_today')
        dns_queries_today=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
    }
    get_adsblockedtoday(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.ads_blocked_today')
        ads_blocked_today=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
    }
    get_adspercentagetoday(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.ads_percentage_today')
        ads_percentage_today=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }

    get_domainsblocked
    get_dnsqueriestoday
    get_adsblockedtoday
    get_adspercentagetoday

    {
        echo "Domains Blocked: $domains_blocked"
        echo "DNS Queries Today: $dns_queries_today"
        echo "Ads Blocked Today: $ads_blocked_today"
        echo "Ads Percentage Today: $ads_percentage_today"
    } > "$CACHE_FILE"

    # Make sure to remove the lock file (may be redundant)
    rm -rf "$LOCK_FILE"
}

case "$1" in
    -c|--cached)
        cat "$CACHE_FILE"
        ;;
    -do|--domains)
        awk '/Domains Blocked/ { print $3 }' "$CACHE_FILE"
        ;;
    -dn|--dns)
        awk '/DNS Queries Today/ { print $4 }' "$CACHE_FILE"
        ;;
    -ab|--ads-blocked)
        awk '/Ads Blocked Today/ { print $4 }' "$CACHE_FILE"
        ;;
    -ap|--ads-percentage)
        awk '/Ads Percentage Today/ { print $4 }' "$CACHE_FILE"
        ;;
    -f|--force)
        rm -rf "$LOCK_FILE"
        run_pihole_query
        ;;
    *)
        run_pihole_query
        ;;
esac