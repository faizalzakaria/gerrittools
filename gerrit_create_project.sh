#!/bin/bash


# Export GERRIT_SERVER
TEST="TRUE"

####################################################################
# Functions
####################################################################

function f_pretty_print {
  echo -e "\e[1;32m $1\e[0m"
}

function f_check_error {
  if [ "$2" != "" ]; then
    f_pretty_print "$1"
    exit 1
  fi
}

function f_print_usage {
  echo -e "\033[1;32m"
  cat << EOF

====================================================
    SET GERRIT_SERVER
    E.G : 
        export GERRIT_SERVER="toto.mama.com"
        export REMOTE_SERVER="ssh://toto.mama.com:29418" [Optional]
    $0 <project_name> <parent_name> [branch_name] [remote_path]

====================================================

EOF

  echo -e "\033[0m"
}

function f_execute {
  if [ "$TEST" == "TRUE" ]; then
    echo $1
  else
    eval $1
  fi
}

# $1 project name
# $2 parent name
function create_project() {
  f_execute "ssh $GERRIT_SERVER gerrit create-project --name $1 || ERR=\"y\""
  f_check_error "Failed to create gerrit project ..." $ERR
  f_execute "ssh $GERRIT_SERVER gerrit set-project-parent --parent $2 $1 || ERR=\"y\""
  f_check_error "Failed to set project parent ..." $ERR
}

function add_remote() {
  f_execute "git remote add origin $1 || ERR=\"y\""
  f_check_error "Failed to add remote '$1' ..." $ERR
}

function init_project() {
  pushd /tmp
  local dir=`mktemp -d`
  cd $dir
  git init
  touch README
  git add -A
  git commit -m"Init commit"
  local branch="master"
  if [ "$1" != "" ]; then
    branch=$1
  fi

  local remote="ssh://${GERRIT_SERVER}:29418/$project_name"
  if [ "$2" != "" ]; then
    remote=$2
  fi

  add_remote $remote
  f_execute "git push origin master:refs/heads/${branch} || ERR=\"y\""
  f_check_error "Failed to push to server ..." $ERR

  rm -rf $dir
}


################ MAIN #############################3

if [ $# -lt 2 ]; then
  f_print_usage
  exit 1
fi

project_name=$1
project_parent=$2

create_project $project_name $project_parent
init_project $3 $4 $project_name
