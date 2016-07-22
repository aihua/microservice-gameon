#!/bin/bash
#
# Copyright 2016 IBM Corporation
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


set -x

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "$1" == "start" ]; then
    echo "starting platform services (kafka, ELK stack, couchdb, a8 controller,registry,gateway)"
    docker-compose -f $SCRIPTDIR/platformservices.yml up -d
    echo "waiting for the platform to initialize.."
    sleep 60
    AR=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' registry ):8080
    AC=localhost:31200
    KA=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' kafka ):9092
    echo "Setting up a new tenant named 'local'"
    read -d '' tenant << EOF
{
    "credentials": {
        "kafka": {
            "brokers": ["${KA}"],
            "sasl": false
        },
        "registry": {
            "url": "http://${AR}",
            "token": "local"
        }
    }
}
EOF
    echo $tenant | curl -H "Content-Type: application/json" -H "Authorization: local" -d @- "http://${AC}/v1/tenants"
elif [ "$1" == "stop" ]; then
    echo "Stopping control plane services..."
    docker-compose -f $SCRIPTDIR/platformservices.yml kill
    docker-compose -f $SCRIPTDIR/platformservices.yml rm -f
else
    echo "usage: $0 start|stop"
    exit 1
fi
