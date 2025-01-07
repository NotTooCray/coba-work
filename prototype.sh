#!/bin/bash
hosts=("aopfmp02" "aopfmp03" "aopfmp04" "aopfmp05" "aopfmp06")
LOG_FILES=( #aopfmp02
           "/aop/aop-new/logs/dare_p8843/dare-p8844.log" "/aop/aop-new/logs/regws_p8874/regws_p8874.log"
           "/aop/aop-new/logs/dare_p8843/dare-p8843.log" "/aop/aop-new/logs/regws_p8873/regws_p8873.log"
           "/aop/aop-new/logs/aop-jobs_p8442/aop-jobs_p8442.log"
            #aopfmp03 
           "/aop/aop-new/logs/aop-connectivity_p8443/aop-connectivity_p8443.log"
           "/aop/aop-new/logs/aop-connectivity_p8444/aop-connectivity_p8444.log"
           "/aop/aopx/logs/workflow-service/workflow-service.log"
           "/aop/aopx/logs/portal-service/portal-service.log"
           "/aop/aopx/logs/hive-service/hive-service.log"
           "/aop/aopx/logs/email-service/email-service.log"
           "/aop/aopx/logs/authserver/authserver.log"
            #aopfmp04
           "/aop/aopx/logs/authserver/authserver.log"
           "/aop/aop-new/logs/dare_job_p8853/dare-job-p8853.log"
           "/aop/aop-new/logs/dare_job_p8853/dare-gic-p8853.log"
           "/aop/aop-new/logs/dare_job_p8853/dare-mifid-p8853.log"
OUTPUT_DIR="/users/ta2aopp/stash/"

check_uptime() {
    local host=$1
    timeout 5 ssh -n "$host" uptime 2>/dev/null
    local status=$?
    
    if [ $status -eq 0 ]; then
        return 0
    elif [ $status -eq 124 ]; then
        echo "Connection timed out"
        return 1
    else
        echo "Connection failed"
        return 1
    fi
}

for host in "${hosts[@]}"; do
    echo -n "$host: "
    if output=$(check_uptime "$host"); then
        echo "$output"
    else
        echo "ERROR: $output"
    fi
done



           

