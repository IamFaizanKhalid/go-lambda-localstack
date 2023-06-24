#!/bin/sh

source ./scripts/env.sh

awslocal logs tail /aws/lambda/${LAMBDA_NAME} \
	--follow \
	--since ${TIMESTAMP}
