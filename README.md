# nagios_check_scripts
Some custom scripts I wrote for nagios tasks.
This was initially based off of a similar Ruby script created by obfuscurity (https://github.com/obfuscurity/nagios-scripts), but since it did not do some things I was looking for I wrote my own version with bash and awk.

get_graphite.sh is used for nagios to check graphite metrics with passed warning and critical threshold and will return a response to graphite as well as an optional link to a 24 hour graphite graph if specified

get_graphite.sh usage:
```
-h            prints this help
-u STRING     [required] graphite URL (required to include http:// or https://)
-m STRING     [required] graphite metric (NOTE: do not use alias() function, use -A param instead)
-S VALUE      duration relative start/from in minutes (default 5)
-E VALUE      duration relative end/util in minutes (default 0)
-L [connected|staircase]
              graph lineMode (default connected)
-W VALUE      [required] metric warning threshold
-C VALUE      [required] metric critical threshold
-U STRING     metric units
-A STRING     metric alias
-f [most_recent|sum|average|max]
              metric calculation function across all metrics
                 (default: most_recent [works best with only one metric])
-G            attach graph link to output
```
    
get_graphite.sh example:
```
./check_graphite.sh -u graphite.hostname.com -m 'metric.name.here' -S 10 -W 4000 -C 5000
./check_graphite.sh -u graphite.hostname.com -m 'metric.name.here' -S 30 -E 10 -W 40 -C 10 -A "metric alias" -U "metric units per day" -G 
```
    
Example Nagios Configuration:

graphite.cfg:
```
# check_garphite command usage:     check_graphite!<graphite_metric>!<warning_threshold>!<critical_threshold>!<from_minutes>!<until_minutes>!<metric alias/name to be displayed>!<metric units>
define command {
    command_name            check_graphite
    command_line            /usr/lib/nagios/plugins/check_graphite.sh -u graphite.hostname.com -m "$ARG1$" -W $ARG2$ -C $ARG3$ -S $ARG4$ -E $ARG5$ -A "$ARG6$" -U "$ARG7$" 2>&1
}
    
# example command to check graphite for metrics 60 minutes from now up to 5 minutes ago
define service {
    hostgroup_name          graphite-checks
    servicegroups           graphite-checks
    service_description     simple_graphite_check
    check_command           check_graphite!graphite.example.HOUR_IN_DAY!9!17!60!5!Hour in Day!Hour
    use                     generic-service
    contact                 me@email.com
}
````
   
