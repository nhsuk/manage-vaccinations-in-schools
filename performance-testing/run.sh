#!/usr/bin/env bash


# Usage: run.sh [options] <session_slug>
# Options:
#  -h, --help  Display this help message and exit
#  -d, --duration  Duration of the test in seconds
#  -r, --ramp-up  Ramp-up time in seconds

# Parse options
JMETER_PARAMS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      echo "Usage: $0 [options] <session_slug>"
      echo "Options:"
      echo "  -h, --help  Display this help message and exit"
      echo "  -d, --duration  Duration of the test in seconds"
      echo "  -r, --ramp-up  Ramp-up time in seconds"
      exit 0
      ;;
    -A|--auth-token)
      JMETER_PARAMS+=("-JAuthToken=$2")
      shift 2
      ;;
    -d|--duration)
      JMETER_PARAMS+=("-JDuration=$2")
      shift 2
      ;;
    -r|--ramp-up)
      JMETER_PARAMS+=("-JRampUp=$2")
      shift 2
      ;;
    -T|--threads)
      JMETER_PARAMS+=("-JThreads=$2")
      shift 2
      ;;
    -V|--vaccinations)
      JMETER_PARAMS+=("-JVaccinationLoop=$2")
      shift 2
      ;;
    *)
      SESSION_SLUG=$1
      shift
      ;;
  esac
done

if [ -z "$SESSION_SLUG" ]; then
  echo "Usage: $0 [options] <session_slug>"
  exit 1
fi

# Warn the user if AuthToken is not set
if [[ ! " ${JMETER_PARAMS[@]} " =~ " -JAuthToken=" ]]; then
  echo "!WARNING! AuthToken is not set. Tests will fail if the env is behind basic auth."
fi

# bin/jmeter -n -t ../Mavis_NURSE.jmx -l ../mavis-perf-test-2025-04-02-write.jtl -JSessionSlug=GrjmypgJXN -Jsample_varables=PatientInfo_matchNr,PatientId,Authenticity_Token,RandomNumber -JDuration=300 -JRampUp=10
DATE=$(date '+%Y%m%d%H%M%S')

echo bin/jmeter -n -t ../Mavis_NURSE.jmx -l ../mavis-perf-test-${DATE}.jtl -JSessionSlug=${SESSION_SLUG} "${JMETER_PARAMS[@]}"
