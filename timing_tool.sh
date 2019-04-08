#!/bin/bash

now() {
  echo $(date "+%Y-%m-%d %H:%M:%S")
}

startTiming() {
    echo "$(now): execution started."
    SECONDS=0
}

finishTiming() {
    echo "$(now): execution finished."

    hrs=$(($SECONDS / 3600))
    mins=$(($(($SECONDS % 3600)) / 60))
    secs=$(($SECONDS % 60))

    if [[ "$hrs" == "0" && "$mins" == "0" ]]; then
        echo "Elapsed: $(($secs))s"
    elif [[ "$hrs" == "0" ]]; then
        echo "Elapsed: $(($mins))m $(($secs))s"
    else
        echo "Elapsed: $(($hrs))h $(($mins))m $(($secs))s"
    fi
}

export -f now
export -f startTiming
export -f finishTiming