#!/bin/sh

source ./scripts/env.sh

# This will create docker container for localstack
docker-compose up -d

[ $? == 0 ] || fail 1 "Failed: Docker / compose / up"


# Building for lambda's architecture: linux/amd64
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ${API_NAME} .

[ $? == 0 ] || fail 2 "Failed: Go / build / ${API_NAME}"


zip -r ${API_NAME}.zip ${API_NAME}

[ $? == 0 ] || fail 3 "Failed: zip / ${API_NAME}"


OUTPUT=$(awslocal lambda create-function \
    --region ${AWS_REGION} \
    --function-name ${LAMBDA_NAME} \
    --runtime go1.x \
    --handler ${API_NAME} \
    --timeout 30 \
    --memory-size 128 \
    --zip-file fileb://${API_NAME}.zip \
    --role "arn:aws:iam::000000000000:role/irrelevant" \
    --environment "Variables={$ENVS}") # Passing variables read from .env

[ $? == 0 ] || fail 4 "Failed: AWS / lambda / create-function"


LAMBDA_ARN=$(awslocal lambda list-functions --query "Functions[?FunctionName==\`${LAMBDA_NAME}\`].FunctionArn" --output text --region ${AWS_REGION})

OUTPUT=$(awslocal apigateway create-rest-api \
    --region ${AWS_REGION} \
    --name ${API_NAME})

[ $? == 0 ] || fail 5 "Failed: AWS / apigateway / create-rest-api"


API_ID=$(awslocal apigateway get-rest-apis --query "items[?name==\`${API_NAME}\`].id" --output text --region ${AWS_REGION})
PARENT_RESOURCE_ID=$(awslocal apigateway get-resources --rest-api-id ${API_ID} --query 'items[?path==`/`].id' --output text --region ${AWS_REGION})

OUTPUT=$(awslocal apigateway create-resource \
    --region ${AWS_REGION} \
    --rest-api-id ${API_ID} \
    --parent-id ${PARENT_RESOURCE_ID} \
    --path-part "{any+}")

[ $? == 0 ] || fail 6 "Failed: AWS / apigateway / create-resource"


RESOURCE_ID=$(awslocal apigateway get-resources --rest-api-id ${API_ID} --query 'items[?path==`/{any+}`].id' --output text --region ${AWS_REGION})

OUTPUT=$(awslocal apigateway put-method \
    --region ${AWS_REGION} \
    --rest-api-id ${API_ID} \
    --resource-id ${RESOURCE_ID} \
    --http-method ANY \
    --authorization-type "NONE")

[ $? == 0 ] || fail 7 "Failed: AWS / apigateway / put-method"


OUTPUT=$(awslocal apigateway put-integration \
    --region ${AWS_REGION} \
    --rest-api-id ${API_ID} \
    --resource-id ${RESOURCE_ID} \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations \
    --passthrough-behavior WHEN_NO_MATCH)

[ $? == 0 ] || fail 8 "Failed: AWS / apigateway / put-integration"


OUTPUT=$(awslocal apigateway create-deployment \
    --region ${AWS_REGION} \
    --rest-api-id ${API_ID} \
    --stage-name ${STAGE})

[ $? == 0 ] || fail 9 "Failed: AWS / apigateway / create-deployment"


ENDPOINT=http://localhost:4566/restapis/${API_ID}/${STAGE}/_user_request_

echo "API available at: ${ENDPOINT}"
echo
echo "Testing: GET ${ENDPOINT}/ping"
curl -i ${ENDPOINT}/ping

[ $? == 0 ] || fail 10 "Failed: curl / GET"
