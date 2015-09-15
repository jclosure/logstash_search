#!/bin/bash

## THIS IS A SPECIFIC SCRIPT TO RUN THE EMAILER AS A CRON JOB
## USE THIS AS INSPIRATION FOR YOUR ENVIRONMENT
## YOU CAN SIMPLY SOFT-LINK THIS SCRIPT TO /etc/cron.hourly/run_emailer.sh
## MAKE SURE TO: chmod +x run_emailer.sh 
## EXAMPLE: ln -s /opt/tools/logstash_search/run_emailer.sh /etc/cron.hourly/run_emailer.sh

#DIR=$( cd "$( /usr/bin/dirname "${BASH_SOURCE[0]}" )" && pwd )


#DIR=/opt/tools/logstash_search

# ref: http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

cd $DIR

HOME=/root

PATH="/root/.rbenv/bin:$PATH"
eval "$(rbenv init -)"


ruby ./lib/emailer.rb qa 1 ./config.yml
ruby ./lib/emailer.rb prod 1 ./config.yml
