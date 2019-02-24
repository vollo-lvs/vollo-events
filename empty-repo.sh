#!/bin/bash
ftpsite="repo.vollo.nl"
ftpuser="vollo_repo"
ftppass=$VOLLO_REPO_PW
putdir="repo.vollo.nl/snapshots/nl/vollo/events/vollo-events/${PROJECT_VERSION}"
newline=$'\n'

if [[ $PROJECT_VERSION == "" ]] ; then echo "No project version defined" ; exit 1 ; fi
if [[ !($PROJECT_VERSION =~ ^.*-SNAPSHOT$) ]] ; then echo "Not a snapshot version" ; exit 0 ; fi
if [[ $VOLLO_REPO_PW == "" ]] ; then echo "No repo password defined" ; exit 1 ; fi

listing=`ftp -i -n $ftpsite <<EOMYF
user $ftpuser $ftppass
binary
cd $putdir
ls
quit
EOMYF
`
lista=( $listing )

for ((FNO=0; FNO<${#lista[@]}; FNO+=9));do
  last_version="0"
  if [[ ${lista[`expr $FNO+8`]} =~ ^.*-([0-9]+)\..+ ]] ; then
    version="${BASH_REMATCH[1]}"
    if [[ $version -gt $last_version ]] ; then
      last_version=$version
    fi
  fi
done
echo Last version is $last_version
delete_cmd=""
for ((FNO=0; FNO<${#lista[@]}; FNO+=9));do
  if [[ ${lista[`expr $FNO+8`]} =~ ^.*-([0-9]+)\..+ ]] ; then
    version="${BASH_REMATCH[1]}"
    if [[ $version -lt $last_version ]] ; then
      delete_cmd="$delete_cmd${newline}delete ${lista[`expr $FNO+8`]}"
    fi
  fi
done
if [[ $delete_cmd == "" ]] ; then
  echo Nothing to delete
else
  echo Removing old versions
  ftp -i -n $ftpsite <<EOMYF2
  user $ftpuser $ftppass
  binary
  cd $putdir
  $delete_cmd
  quit
EOMYF2
fi
