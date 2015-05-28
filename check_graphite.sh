#!/bin/bash

# nagios return values
NAGIOS_OK=0
NAGIOS_WARNING=1
NAGIOS_CRITICAL=2
NAGIOS_UNKNOWN=3

#optional values with defaults
line_mode=connected
start_duration=5
end_duration=0

#function usage
function usage() {
    cat<<EOF
usage $0 [options]
options:
    -h            prints this help
    -u STRING     [required] graphite URL
    -m STRING     [required] graphite metric (NOTE: do not use alias() function, use -A param instead)
    -S VALUE      duration relative start/from in minutes (default 5)
    -E VALUE      duration relative end/util in minutes (default 0)
    -L [connected|staircase]
                  graph lineMode (default connected)
    -W VALUE      [required] metric warning threshold
    -C VALUE      [required] metric critical threshold
    -U STRING     metric units
    -A STRING     metric alias
    -G            attach graph link to output
EOF
}

# get options
# TODO: make long_options possible if possible
while getopts ":hu:m:S:E:L:W:C:U:A:G" opt; do
    case "${opt}" in
        h)
            usage
            exit 0
            ;;
        u)
            url=${OPTARG}
            ;;
        m)
            #metric spaces needs to be encoded and doulbe quotes replaced with single quotes
            #slight redundancy if user passes alias function, remove when unecessary
            metric=$(echo ${OPTARG} | sed 's/ /%20/g' | sed "s/\"/'/g")
            ;;
        S)
            start_duration=${OPTARG}
            ;;
        E)
            end_duration=${OPTARG}
            ;;
        L)
            line_mode=${OPTARG}
            ;;
        W)
            warn_thresh=${OPTARG}
            ;;
        C)
            crit_thresh=${OPTARG}
            ;;
        U)
            units=${OPTARG}
            ;;
        A)
            metric_alias=${OPTARG}
            ;;
        G)
            link_graph="true"
            ;;
        *)
            usage
            exit $NAGIOS_UNKNOWN
            ;;
     esac
done

# check that all required metrics are set
if [ -z "${url}" ] ||
   [ -z "${metric}" ] ||
   [ -z "${warn_thresh}" ] ||
   [ -z "${crit_thresh}" ]; then
    echo "UNKNOWN $0: Failed to pass all required params"
    exit $NAGIOS_UNKNOWN
fi

# query to get graphite metrics in raw format (consult URL API for format details)
query="https://${url}/render/?target=${metric}&format=raw&from=-${start_duration}mins&until=-${end_duration}mins"

#create temp_file for use of this script
tmp_file=`mktemp ./tmp.XXXXXXXXXX`
res=0
curl -o $tmp_file -s $query || res=$?

# throw UNKNOWN if curl had an issue with contacting graphite
if [ ! $res -eq 0 ]; then
    echo "UNKNOWN Error Calling Graphite at \"${url}\" [Curl Error $res]"
    exit $NAGIOS_UNKNOWN
fi

if [ ! -s $tmp_file ]; then
    rm $tmp_file
    echo "UNKNOWN No Graphite Data Returned"
    exit $NAGIOS_UNKNOWN
fi

# get all raw data from tmp_file
all_raw_data=`cat $tmp_file`

# empty tmp_file for reuse
echo "" > $tmp_file

# remove headers from raw data and separate metric data with newlines
for line in $all_raw_data; do
    raw_data=${line##*|}
    echo $raw_data >> $tmp_file
done

# use awk to process result and provide base message
# awk script expects multiple metrics split by newlines
#   and values to be comma separated and empty values as "None"
result=$(cat $tmp_file | awk -f process_raw_graphite_data.awk -v warn_thresh=$warn_thresh crit_thresh=$crit_thresh metric="${metric_alias-$metric}")

# create graph link
# if an alias is specified for the metric, encode alias spaces and wrap
#    alias function around metric for graphite
data_metric=$metric
if [ ! -z "$metric_alias" ]; then
    encoded_alias=$(echo $metric_alias | sed 's/ /%20/g' | sed "s/\"/'/g")
    data_metric="alias(${metric},'${encoded_alias}')"
fi
#create html graph link for past 24 hours
graph_link="<a target=\"_blank\" href=\"https://${url}/render/?target=${data_metric}&from=-24hrs&lineMode=${line_mode}&width=700&height=450\"> 24h Graph </a>"

# echo output to Nagios
echo $result $units ${link_graph+$qraph_link}

# remove temporary file
rm $tmp_file

# check result message and exit accordingly
case $result in
    OK*)
        exit $NAGIOS_OK
        ;;
    WARNING*)
        exit $NAGIOS_WARNING
        ;;
    CRITICAL*)
        exit $NAGIOS_CRITICAL
        ;;
    *)
        exit $NAGIOS_UNKNOWN
        ;;
esac
