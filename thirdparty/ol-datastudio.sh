#!/bin/bash
#
# datastudio  Start/Stop the Oracle Labs Data Studio notebooks
#
# chkconfig: 5 90 60

# If anything goes wrong, fail
exit_err () {
  echo "There was an error, please review the output above and, if appropriate, report a bug on https://github.com/oracle/big-data-lite with the full output of the script."
  exit 1
}
trap 'exit_err' ERR

dir=$(dirname "$(readlink -f $0)")
thirdparty_root=$dir/inst
datastudio_version=0.7.0-SNAPSHOT
datastudio_pkg_url=http://pgx.us.oracle.com/stuff/datastudio-${datastudio_version}.zip
datastudio_root=$thirdparty_root/datastudio-$datastudio_version
datastudio_db_file=$datastudio_root/datastudio.db
datastudio_port=7008

check_running () {
  if [ ! -f $datastudio_root/server_pid.txt ]; then
    return 1
  fi

  if pgrep -g $(cat $datastudio_root/server_pid.txt) &> /dev/null; then
    return 0
  fi

  rm -rf $datastudio_root/server_pid.txt
  return 1
}

cd $dir

if [ "$1" == "install" ]; then
  mkdir -p $thirdparty_root
  datastudio_pkg=$thirdparty_root/$(basename $datastudio_pkg_url)
  echo "Setting up Oracle Labs Data Studio..."

  echo "Getting Oracle Labs Data Studio version ${datastudio_version}..."
  [ -f $datastudio_pkg ] ||
    curl $datastudio_pkg_url -o $datastudio_pkg
  echo "Unpacking Oracle Labs Data Studio..."
  unzip $datastudio_pkg -d $datastudio_root

  echo "Done; you can run $0 {start | stop} to start / stop the Oracle Labs Data Studio service"

  (
  a=""
  while [ "$a" != "y" ] && [ "$a" != "n" ]; do
    echo "Add to system services? (works on Oracle Linux, requires sudo) [y/n]"
    read a
  done
  [ "$a" == "n" ] && exit 0
  sudo rm -f /etc/init.d/datastudio
  sudo ln -s "$(readlink -f $0)" /etc/init.d/datastudio
  sudo chkconfig --add datastudio
  )

  exit 0
elif [ "$1" == "uninstall" ]; then
  rm -rf $datastudio_root

  [ -f /etc/init.d/datastudio ] && (sudo rm -f /etc/init.d/datastudio)

  exit 0
elif [ "$1" == "start" ]; then
  if check_running; then
    echo "Error: Datastudio server already running (pgid: $(cat $datastudio_root/server_pid.txt), stop it first."
    exit 0
  fi
  (
  pid=$$
  echo $pid > $datastudio_root/server_pid.txt
  cd $datastudio_root/datastudio/bin
  ./starter --database-file=$datastudio_db_file --port=$datastudio_port
  ) &

  (
  ret=1
  while [ $ret -ne 0 ]; do
    curl http://localhost:$datastudio_port &> /dev/null
    ret=$?
  done
  )

  exit 0

elif [ "$1" == "stop" ]; then
  if ! check_running; then
    echo "Error: Data Studio notebook not running."
    exit 0
  fi
  kill -SIGTERM -- -$(cat $datastudio_root/server_pid.txt)
  rm $datastudio_root/server_pid.txt

  exit 0

elif [ "$1" == "cleandb" ]; then
  rm -f $datastudio_db_file

  exit 0
elif [ "$1" == "status" ]; then
  trap '' ERR

  if check_running; then
    echo "Data Studio notebook running (pgid: $(cat $datastudio_root/server_pid.txt))."
    exit 0
  else
    echo "Data Studio notebook not running."
    exit 1
  fi
fi

echo "Usage: $0 {install | uninstall | start | stop | status | cleandb}"
exit -1

