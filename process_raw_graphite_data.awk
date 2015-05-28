#!/bin/awk -f

# expected input:
# This awk script will expect the input to be comma separated values
#   of metric data, with empty data being "None"
# If multiple metrics are returned (i.e. a wildcard * is used)
#   then multiple metrics data is delimitted by a newline.
#   Please note that some functions will not have perfectly
#   expected behavior when used (example: most_recent with multiple metrics)

#function descriptions:
#    most_recent: will get most recent metric across all metrics
#                 (last one will take precedence)
#                 NOTE: better to use 'most_recent' with only one metric
#                   data being processed for best expected results
#    max:         get max value across all metric data
#    average:     will get average value across all metric data
#                 (note: not just mean across most recent values by metric)
#    sum:         Sum of all values in data points
#                 (unknown function names will default to this)

BEGIN{
    total = 0.0;
    total_count = 0;
    recent_index = 0;
    max = 0.0;
    #warn_thresh passed as param
    #crit_thresh passed as param
    #metric passed as param
    #func passed as param
    if(length(func) == 0) { func = "sum" }
    FS = ","
}

{
    val = 0.0;
    count = 0;

    # iterate through data
    for(i=1; i < NF; i++) {
        if($i != "None") {
            if(func == "most_recent" && i >= recent_index) {
                val = $i
                recent_index = i;
            } else if (func == "max" && $i > max) {
                val = $i;
                max = val;
            } else {
                val += $i;
            }
            count += 1;
        }
    }

    # combine metric with end-result
    if(func == "average") {
        total_count += count;
        total += val;
    } else if (func == "most_recent" || func == "max" ) {
        total = val;
    } else {
        total += val;
    }

}

END{
    if(func == "average") {
        total_count = (total_count > 0 ? total_count : 1);
        total = (total / total_count);
    }

    if(crit_thresh > warn_thresh) {
        if(total >= crit_thresh) {
            print "CRITICAL ", metric, ": ", total
        } else if(total >= warn_thresh) {
            print "WARNING ", metric, ": ", total
        } else {
            print "OK: ", metric, ": ", total
        }
    } else {
        if(total <= crit_thresh) {
            print "CRITICAL ", metric, ": " total
        } else if(total <= warn_thresh) {
            print "WARNING ", metric, ": ", total
        } else {
            print "OK ", metric, ": ", total
        }
    }
}
