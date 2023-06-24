#!/bin/sh

source ./scripts/env.sh

GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ${API_NAME} .

[ $? == 0 ] || fail 1 "Failed: Go / build / ${API_NAME}"


zip -r ${API_NAME}.zip ./bin/*

[ $? == 0 ] || fail 2 "Failed: zip / ${API_NAME}"


OUTPUT=$(awslocal lambda update-function-code \
		--function-name ${LAMBDA_NAME} \
		--zip-file fileb://${API_NAME}.zip)

[ $? == 0 ] || fail 3 "Failed: AWS / lambda / update-function-code"

echo "Lambda code updated..."
