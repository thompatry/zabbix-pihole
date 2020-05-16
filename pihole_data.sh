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

    get_uniquedomains(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.unique_domains')
        unique_domains=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
    get_queriesforwarded(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.queries_forwarded')
        queries_forwarded=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
    get_queriescached(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.queries_cached')
        queries_cached=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
    get_clientseverseen(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.clients_ever_seen')
        clients_ever_seen=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
    get_uniqueclients(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.unique_clients')
        unique_clients=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
    get_dnsqueriesalltypes(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.dns_queries_all_types')
        dns_queries_all_types=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
        
    get_replyNODATA(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.reply_NODATA')
        reply_NODATA=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
    get_replyNXDOMAIN(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.reply_NXDOMAIN')
        reply_NXDOMAIN=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
    get_replyCNAME(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.reply_CNAME')
        reply_CNAME=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
    get_replyIP(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.reply_IP')
        reply_IP=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
    get_privacylevel(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.privacy_level')
        privacy_level=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }
    get_status(){
        rawjson=$(curl -s http://$pihole_server/admin/api.php | jq '.status')
        status=$(echo $rawjson | sed -e 's/\"//g' -e 's/\,//g')
        }

    get_domainsblocked
    get_dnsqueriestoday
    get_adsblockedtoday
    get_adspercentagetoday
    get_uniquedomains
    get_queriesforwarded
    get_queriescached
    get_clientseverseen
    get_uniqueclients
    get_dnsqueriesalltypes
    get_replyNODATA
    get_replyNXDOMAIN
    get_replyCNAME
    get_replyIP
    get_privacylevel
    get_status    

    {
        echo "Domains Blocked: $domains_blocked"
        echo "DNS Queries Today: $dns_queries_today"
        echo "Ads Blocked Today: $ads_blocked_today"
        echo "Ads Percentage Today: $ads_percentage_today"
        echo "Unique Domains: $unique_domains"
        echo "Queries Forwarded: $queries_forwarded"
        echo "Queries Cached: $queries_cached"
        echo "Clients Ever Seen: $clients_ever_seen"
        echo "Unique Clients: $unique_clients"
        echo "DNS Queries All Types: $dns_queries_all_types"
        echo "Reply NODATA: $reply_NODATA"
        echo "Reply NXDOMAIN: $reply_NXDOMAIN"
        echo "Reply CNAME: $reply_CNAME"
        echo "Reply IP: $reply_IP"
        echo "Privacy Level: $privacy_level"
        echo "Status: $status"
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
    -dn|--dnsQ)
        awk '/DNS Queries Today/ { print $4 }' "$CACHE_FILE"
        ;;
    -ab|--ads-blocked)
        awk '/Ads Blocked Today/ { print $4 }' "$CACHE_FILE"
        ;;
    -ap|--ads-percentage)
        awk '/Ads Percentage Today/ { print $4 }' "$CACHE_FILE"
        ;;
    -ud|--unique_domains)
        awk '/Unique Domains/ { print $3 }' "$CACHE_FILE"
        ;;
    -qf|--queries_forwarded)
        awk '/Queries Forwarded/ { print $3 }' "$CACHE_FILE"
        ;;
    -qc|--queries_cached)
        awk '/Queries Cached/ { print $3 }' "$CACHE_FILE"
        ;;
    -ces|--clients_ever_seen)
        awk '/Clients Ever Seen/ { print $4 }' "$CACHE_FILE"
        ;;
    -uc|--unique_clients)
        awk '/Unique Clients/ { print $3 }' "$CACHE_FILE"
        ;;
    -dna|--dns_queries_all_types)
        awk '/DNS Queries All Types/ { print $5 }' "$CACHE_FILE"
        ;;
    -rna|--reply_NODATA)
        awk '/Reply NODATA/ { print $3 }' "$CACHE_FILE"
        ;;
    -rnx|--reply_NXDOMAIN)
        awk '/Reply NXDOMAIN/ { print $3 }' "$CACHE_FILE"
        ;;
    -rcn|--reply_CNAME)
        awk '/Reply CNAME/ { print $3 }' "$CACHE_FILE"
        ;;
    -rip|--reply_IP)
        awk '/Reply IP/ { print $3 }' "$CACHE_FILE"
        ;;
    -pl|--privacy_level)
        awk '/Privacy Level/ { print $3 }' "$CACHE_FILE"
        ;;
    -s|--status)
        awk '/Status/ { print $2 }' "$CACHE_FILE"
        ;;

    -f|--force)
        rm -rf "$LOCK_FILE"
        run_pihole_query
        ;;
    *)
        run_pihole_query
        ;;
esac
