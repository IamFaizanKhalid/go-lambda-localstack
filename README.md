This demonstrates how to configure your Golang Lambda function (that uses Redis) on localstack using docker.

## Prerequisites:
- docker-compose
- [AWS CLI](https://aws.amazon.com/cli/)

## Usage
- Run `./scripts/setup.sh` to set up.
- Run `./scripts/update.sh` to update lambda with your latest code.

### Remember
For connection to the Redis docker container from the localstack docker container, use container name instead of `localhost`.

## Based on
- https://gist.github.com/crypticmind/c75db15fd774fe8f53282c3ccbe3d7ad
