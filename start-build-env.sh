#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

cd "$(dirname "$0")"

docker build -t presto-build dev-support/docker

if [ "$(uname -s)" == "Linux" ]; then
  USER_NAME=${SUDO_USER:=$USER}
  USER_ID=$(id -u "${USER_NAME}")
  GROUP_ID=$(id -g "${USER_NAME}")
else # boot2docker uid and gid
  USER_NAME=$USER
  USER_ID=1000
  GROUP_ID=50
fi


docker build -t "presto-build-${USER_NAME}" - <<UserSpecificDocker
FROM presto-build
RUN groupadd --non-unique -g ${GROUP_ID} ${USER_NAME}
RUN useradd -g ${GROUP_ID} -u ${USER_ID} -k /root -m ${USER_NAME}
ENV HOME /home/${USER_NAME}
UserSpecificDocker

docker run --rm=true -t -i \
  -v "${PRESTO_HOME}:/home/${USER_NAME}/presto" \
  -w "/home/${USER_NAME}/presto" \
  -v "${HOME}/.m2:/home/${USER_NAME}/.m2" \
  -u "${USER_NAME}" \
  "presto-build-${USER_NAME}"
