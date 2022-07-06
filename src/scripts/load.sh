#!/bin/bash
mkdir -p /tmp/parameterstore/
for row in $(aws ssm describe-parameters --no-paginate --parameter-filters ${PARAM_FILTER} | jq -c '.Parameters[]'| jq -c 'del(.Description)'); do
  _jq() {
    PARNAME=$(jq -r '.Name' <<< "${row}")
    PARDATA=$(aws ssm get-parameters --with-decryption --names "${PARNAME}" | jq '.Parameters[].Value')
    if [ -z "$PARDATA" ]
    then
      echo "${PARNAME} appears to be empty. Please double check the value of this parameter."
      exit 1
    fi
    if [ -f /tmp/parameterstore/"${PARNAME}" ]
    then
      echo "This value has already been stored. Is this value stored twice?"
      exit 1
    fi
    echo "${PARDATA}" >> /tmp/parameterstore/"${PARNAME}"
    echo "export ${PARNAME}=$(cat /tmp/parameterstore/"${PARNAME}")" >> /tmp/parameterstore/PARAMETERSTORESOURCEFILE
  }
  _jq
done
cat /tmp/parameterstore/PARAMETERSTORESOURCEFILE >> $BASH_ENV
source $BASH_ENV
