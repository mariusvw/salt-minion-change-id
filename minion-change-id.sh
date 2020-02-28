#!/bin/sh

# $1, old name
# $2, new name

usage() {
    cat << EOF

Usage: $0 old-id new-id

EOF
}

if [ $# -eq 0 ] ; then
    usage
    exit 1
fi

id_old=$1
id_new=$2

if [ -z "$id_old" ]
then
    echo "Old name is required."
    usage
    exit
fi
if [ -z "$id_new" ]
then
    echo "New name is required."
    usage
    exit
fi

echo "[+] Determine master OS"
MASTER_OS=$(salt-call --local --out=txt -l quiet grains.get os | awk -F': ' '{ print $2 }')

if [ "${MASTER_OS}" = "FreeBSD" ]
then
    master_pki="/usr/local/etc/salt/pki"
elif [ "${MASTER_OS}" = "GNU/Linux" ] || [ "${MASTER_OS}" = "Ubuntu" ] || [ "${MASTER_OS}" = "Raspbian" ]
then
    master_pki="/etc/salt/pki"
else
    echo "Unknown MASTER OS"
    exit
fi

echo "[+] Test if pki data is available"
test ! -f $master_pki/master/minions/$id_old && echo "Old minion name does not exist" && exit
test -f $master_pki/master/minions/$id_new && echo "New minion name already in use" && exit

echo "[+] Test if minion is reachable"
salt -l quiet "$id_old" test.ping
test "$?" -ne 0 && echo "Minion is not online, stopping..." && exit

echo "[+] Determine minion OS"
MINION_OS=$(salt --out=txt -l quiet "$id_old" grains.get os | awk -F': ' '{ print $2 }')
if [ "${MINION_OS}" = "FreeBSD" ]
then
    service="salt_minion"
    user="root"
    group="wheel"
elif [ "${MINION_OS}" = "GNU/Linux" ] || [ "${MINION_OS}" = "Ubuntu" ] || [ "${MINION_OS}" = "Raspbian" ]
then
    service="salt-minion"
    user="root"
    group="root"
else
    echo "Unknown MINION OS"
    exit
fi

echo "[+] Get minion config location"
conf_file="$(salt --out=txt -l quiet "$id_old" config.get conf_file | awk -F': ' '{ print $2 }')"
id_file="${conf_file}_id"
# FIXME needs a better test
if [ "$id_file" = "_id" ]
then
    echo "Failed to locate minion_id file."
    exit
fi

echo "[+] Replace id in minion_id cachefile"
salt -l quiet "$id_old" file.manage_file "$id_file" '' '{}' '' '' $user $group '755' '' base '' contents="$id_new"
test "$?" -ne 0 && echo "Failed to change minion_id content" && exit

echo "[+] Replace id in minion config"
salt -l quiet "$id_old" file.line "$conf_file" content="id: $id_new" match='id:.*' mode=replace quiet=True
test "$?" -ne 0 && echo "Failed to change id in minion config" && exit

echo "[+] Restart minion service"
salt -l quiet "$id_old" cmd.run_bg "sleep 5; salt-call --local service.restart $service"
if [ "$?" -eq 0 ]
then
    mv $master_pki/master/minions/$id_old $master_pki/master/minions/$id_new
    echo "Wait 5 seconds for minion to restart..."
    sleep 5

    retry=0
    echo -n "Waiting for minion to return"
    while true
    do
        echo -n "."

        salt -l quiet "$id_new" test.ping > /dev/null 2>&1
        if [ "$?" -eq 0 ]
        then
            echo
            echo "Minion connected."
            break
        fi

        retry=$(expr $retry + 1)

        if [ "$retry" -gt 9 ]
        then
            echo
            echo "Minion lost, recover manually!"
            break
        fi
    done
else
    echo "Restarting minion failed."
fi
