#!/bin/bash

# Configuration
SERVERS=("aopfmp04" "aopfmp05" "aopfmp06")
LOG_FILES=("/var/log/service1.log" "/var/log/service2.log")
OUTPUT_DIR="/path/to/reports"
DATE=$(date +%Y%m%d)
YESTERDAY=$(date -d "yesterday" +%Y%m%d)

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
REPORT_FILE="$OUTPUT_DIR/server_monitor_$DATE.txt"
YESTERDAY_REPORT="$OUTPUT_DIR/server_monitor_$YESTERDAY.txt"
DIFF_REPORT="$OUTPUT_DIR/server_monitor_${DATE}_diff.txt"

# Function to extract number from percentage
extract_number() {
    echo "$1" | grep -o '[0-9.]*'
}

# Function to collect system metrics
collect_system_stats() {
    local server=$1
    echo -e "\n=== $server ===" >> "$REPORT_FILE"
    echo -e "\nSystem Statistics:" >> "$REPORT_FILE"
    
    # Load average
    echo "Load Average: $(ssh $server "uptime | awk '{print \$(NF-2),\$(NF-1),\$NF}'")" >> "$REPORT_FILE"
    
    # Memory usage
    echo "Memory Usage: $(ssh $server "free -m | awk 'NR==2{printf \"%.2f%%\", \$3*100/\$2}'")" >> "$REPORT_FILE"
    
    # CPU usage
    echo "CPU Usage: $(ssh $server "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}')%" >> "$REPORT_FILE"
    
    # Disk usage
    echo "Disk Usage: $(ssh $server "df -h / | awk 'NR==2{print \$5}'")" >> "$REPORT_FILE"
}

# Function to count log levels
count_log_levels() {
    local server=$1
    local log_file=$2
    
    echo -e "\nLog counts for $log_file:" >> "$REPORT_FILE"
    ssh $server "
        echo 'Info:     '\$(grep -c 'INFO' $log_file)
        echo 'Warning:  '\$(grep -c 'WARNING' $log_file)
        echo 'Error:    '\$(grep -c 'ERROR' $log_file)
    " >> "$REPORT_FILE"
}

# Function to compare metrics with yesterday
compare_with_yesterday() {
    if [ ! -f "$YESTERDAY_REPORT" ]; then
        echo "No previous report found for comparison." >> "$DIFF_REPORT"
        return
    }

    echo "Comparison with yesterday's report - $(date '+%Y-%m-%d %H:%M:%S')" > "$DIFF_REPORT"
    echo "==================================================" >> "$DIFF_REPORT"

    for server in "${SERVERS[@]}"; do
        echo -e "\n=== $server ===" >> "$DIFF_REPORT"
        
        # Extract metrics from today's and yesterday's reports
        TODAY_SECTION=$(sed -n "/=== $server ===/,/===.*===\|$/p" "$REPORT_FILE")
        YESTERDAY_SECTION=$(sed -n "/=== $server ===/,/===.*===\|$/p" "$YESTERDAY_REPORT")

        # Compare memory usage
        TODAY_MEM=$(echo "$TODAY_SECTION" | grep "Memory Usage:" | awk '{print $3}')
        YESTERDAY_MEM=$(echo "$YESTERDAY_SECTION" | grep "Memory Usage:" | awk '{print $3}')
        
        if [ ! -z "$TODAY_MEM" ] && [ ! -z "$YESTERDAY_MEM" ]; then
            MEM_DIFF=$(awk "BEGIN {printf \"%.2f\", $(extract_number $TODAY_MEM) - $(extract_number $YESTERDAY_MEM)}")
            echo "Memory Usage Change: $MEM_DIFF%" >> "$DIFF_REPORT"
        fi

        # Compare CPU usage
        TODAY_CPU=$(echo "$TODAY_SECTION" | grep "CPU Usage:" | awk '{print $3}')
        YESTERDAY_CPU=$(echo "$YESTERDAY_SECTION" | grep "CPU Usage:" | awk '{print $3}')
        
        if [ ! -z "$TODAY_CPU" ] && [ ! -z "$YESTERDAY_CPU" ]; then
            CPU_DIFF=$(awk "BEGIN {printf \"%.2f\", $(extract_number $TODAY_CPU) - $(extract_number $YESTERDAY_CPU)}")
            echo "CPU Usage Change: $CPU_DIFF%" >> "$DIFF_REPORT"
        fi

        # Compare disk usage
        TODAY_DISK=$(echo "$TODAY_SECTION" | grep "Disk Usage:" | awk '{print $3}')
        YESTERDAY_DISK=$(echo "$YESTERDAY_SECTION" | grep "Disk Usage:" | awk '{print $3}')
        
        if [ ! -z "$TODAY_DISK" ] && [ ! -z "$YESTERDAY_DISK" ]; then
            DISK_DIFF=$(awk "BEGIN {printf \"%.2f\", $(extract_number $TODAY_DISK) - $(extract_number $YESTERDAY_DISK)}")
            echo "Disk Usage Change: $DISK_DIFF%" >> "$DIFF_REPORT"
        fi

        # Compare log counts
        for log_file in "${LOG_FILES[@]}"; do
            echo -e "\nLog count changes for $log_file:" >> "$DIFF_REPORT"
            
            # Get today's counts
            TODAY_INFO=$(echo "$TODAY_SECTION" | grep -A3 "$log_file" | grep "Info:" | awk '{print $2}')
            TODAY_WARN=$(echo "$TODAY_SECTION" | grep -A3 "$log_file" | grep "Warning:" | awk '{print $2}')
            TODAY_ERROR=$(echo "$TODAY_SECTION" | grep -A3 "$log_file" | grep "Error:" | awk '{print $2}')
            
            # Get yesterday's counts
            YESTERDAY_INFO=$(echo "$YESTERDAY_SECTION" | grep -A3 "$log_file" | grep "Info:" | awk '{print $2}')
            YESTERDAY_WARN=$(echo "$YESTERDAY_SECTION" | grep -A3 "$log_file" | grep "Warning:" | awk '{print $2}')
            YESTERDAY_ERROR=$(echo "$YESTERDAY_SECTION" | grep -A3 "$log_file" | grep "Error:" | awk '{print $2}')
            
            # Calculate differences
            if [ ! -z "$TODAY_INFO" ] && [ ! -z "$YESTERDAY_INFO" ]; then
                INFO_DIFF=$((TODAY_INFO - YESTERDAY_INFO))
                echo "Info change:     $INFO_DIFF" >> "$DIFF_REPORT"
            fi
            
            if [ ! -z "$TODAY_WARN" ] && [ ! -z "$YESTERDAY_WARN" ]; then
                WARN_DIFF=$((TODAY_WARN - YESTERDAY_WARN))
                echo "Warning change:  $WARN_DIFF" >> "$DIFF_REPORT"
            fi
            
            if [ ! -z "$TODAY_ERROR" ] && [ ! -z "$YESTERDAY_ERROR" ]; then
                ERROR_DIFF=$((TODAY_ERROR - YESTERDAY_ERROR))
                echo "Error change:    $ERROR_DIFF" >> "$DIFF_REPORT"
            fi
        done
    done
}

# Main execution
# Generate today's report
echo "Server Monitoring Report - $(date '+%Y-%m-%d %H:%M:%S')" > "$REPORT_FILE"

for server in "${SERVERS[@]}"; do
    collect_system_stats "$server"
    for log_file in "${LOG_FILES[@]}"; do
        count_log_levels "$server" "$log_file"
    done
done

# Generate comparison report
compare_with_yesterday

echo -e "\nReports generated at:"
echo "Today's report: $REPORT_FILE"
echo "Difference report: $DIFF_REPORT"
