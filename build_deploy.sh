#!/bin/bash

IMAGE_TAG=ntripcaster
IMAGE_REVISION=latest

aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 676440762571.dkr.ecr.us-west-2.amazonaws.com
docker build . -t $IMAGE_TAG
docker tag $IMAGE_TAG:$IMAGE_REVISION 676440762571.dkr.ecr.us-west-2.amazonaws.com/$IMAGE_TAG:$IMAGE_REVISION
docker push 676440762571.dkr.ecr.us-west-2.amazonaws.com/$IMAGE_TAG:$IMAGE_REVISION
