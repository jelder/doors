#!/bin/sh
cd $(dirname $0)
export PATH=~/.rbenv/bin:/usr/local/bin:$PATH
eval "$(rbenv init -)"
. ./env.sh
bundle exec ./door_agent.rb
