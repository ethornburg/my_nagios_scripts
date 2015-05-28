# my_nagios_scripts
Some custom scripts I wrote for nagios tasks.

get_graphite.sh is used for nagios to check graphite metrics with passed warning and critical threshold and will return a response to graphite as well as an optional link to a 24 hour graphite graph if specified

get_graphite.sh usage:

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
    
get_graphite.sh example:

    ./check_graphite.sh -u graphite.hostname.com -m 'metric.name.here' -S 10 -W 4000 -C 5000
    ./check_graphite.sh -u graphite.hostname.com -m 'metric.name.here' -S 30 -E 10 -W 40 -C 10 -A "metric alias" -U "metric units per day" -G 
