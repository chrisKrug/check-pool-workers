#!/bin/sh

_ip_addresses=("172.16.3.6" "172.16.3.9")

check_ldm () {
	nc -z ${_ip_address} 388 > /dev/null
        _ldm_result=$?
        if [[ $_ldm_result -eq 0 ]]; then
                _ldm_status="LDM up"
                if [[ -f "worker-pool/${_ip_address}" ]]; then
                        echo "Worker in pool" > /dev/null
                else
                    	echo "LDM backup. Worker not in pool. Adding" > /dev/null
                        #add IP to pool
                        /usr/sbin/ipvsadm -a -t 172.16.3.68:388 -r ${_ip_address}:388 -m
                        #add worker-pool file
                        touch "worker-pool/${_ip_address}"
                fi
        else
            	_ldm_status="LDM down"
                if [[ -f "worker-pool/${_ip_address}" ]]; then
                        echo "Worker in worker-pool. Removing." > /dev/null
                        #remove IP from pool
                        /usr/sbin/ipvsadm -d -t 172.16.3.68:388 -r ${_ip_address}:388
                        #remove worker-pool file
                        rm -f worker-pool/${_ip_address}
                else
                    	echo "Worker still out of pool" > /dev/null
                fi
        fi
}

ping_host () {
	ping -q -c 1 ${_ip_address} > /dev/null
        _ping_result=$?
        if [[ $_ping_result -eq 0 ]]; then
                _server_status="Server up"
                check_ldm
        else
            	_server_status="Server down"
                #remove IP from pool
                /usr/sbin/ipvsadm -d -t 172.16.3.68:388 -r ${_ip_address}:388
                #remove worker-pool file
                rm -f worker-pool/${_ip_address}
        fi
}

for _ip_address in "${_ip_addresses[@]}"
do
  	echo $_ip_address
        ping_host
        echo $_ping_result $_server_status
        echo $_ldm_result $_ldm_status
done
