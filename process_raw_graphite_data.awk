#!/bin/awk -f

BEGIN{
    total=0.0;
    #warn_thresh passed as param
    #crit_thresh passed as param
    #metric passed as param
    FS=","
}
{
    val=0.0
    count=0
    for(i=1; i < NF; i++){
        if($i != "None") {
            val=$i;
            count+=1;
        }
    }
    total+=val;
}
END{
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
