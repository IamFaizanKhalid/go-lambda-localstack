
export AWS_REGION=us-west-2
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

API_NAME=my-api
LAMBDA_NAME=my-lambda
STAGE=test

alias awslocal="aws --endpoint-url=http://localhost:4566"

# This will read .env file in following format:
# VAR1='VAL1',VAR2='VAL2',VAR3='VAL3'
ENVS=$(awk 'NF' .env | sed -e "s/\(.*\)=\(.*\)/\1='\2'/g" | paste -sd "," -)

# Current time in RFC3339 format
TIMESTAMP=$(date -Iseconds)

function fail() {
    echo $2
    exit $1
}
