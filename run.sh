#!/bin/sh
cd $(dirname $0)
export PATH=~/.rbenv/bin:$PATH
eval "$(rbenv init -)"
echo $PATH
. ./env.sh
bundle exec ./door_agent.rb
