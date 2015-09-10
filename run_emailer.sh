#!/bin/bash

## THIS IS A SPECIFIC SCRIPT TO RUN THE EMAILER AS A CRON JOB
## USE THIS AS INSPIRATION FOR YOUR ENVIRONMENT
## YOU CAN SIMPLY SOFT-LINK THIS SCRIPT TO /etc/cron.hourly/run_emailer.sh
## MAKE SURE TO: chmod +x run_emailer.sh 
## EXAMPLE: ln -s /opt/tools/logstash_search/run_emailer.sh /etc/cron.hourly/run_emailer.sh

#DIR=$( cd "$( /usr/bin/dirname "${BASH_SOURCE[0]}" )" && pwd )


DIR=/opt/tools/logstash_search

cd $DIR

HOME=/root

PATH="/root/.rbenv/bin:$PATH"
eval "$(rbenv init -)"


ruby emailer.rb qa 1
ruby emailer.rb prod 1
