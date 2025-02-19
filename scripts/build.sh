#!/bin/bash
#
# Build the docker images.

set -euo pipefail

source scripts/shared.sh

parse_std_args "$@"

get_ei_executable

echo "pulling previous image for layer cache... "
aws ecr get-login-password --region ${aws_region} \
    | docker login \
        --password-stdin \
        --username AWS \
        "${aws_account}.dkr.ecr.${aws_region}.amazonaws.com/${repository}" &>/dev/null || echo 'warning: ecr login failed'
docker pull $aws_account.dkr.ecr.$aws_region.amazonaws.com/$repository:$full_version-$device &>/dev/null || echo 'warning: pull failed'
docker logout https://$aws_account.dkr.ecr.$aws_region.amazonaws.com &>/dev/null

echo "building image... "
cp -r docker/build_artifacts/* docker/$short_version/
docker build \
    --cache-from $aws_account.dkr.ecr.$aws_region.amazonaws.com/$repository:$full_version-$device \
    --build-arg TFS_VERSION=$full_version \
    --build-arg TFS_SHORT_VERSION=$short_version \
    -f docker/$short_version/Dockerfile.$arch \
    -t $repository:$full_version-$device \
    -t $repository:$short_version-$device \
    -t ovms-serving:2.1-cpu \
    docker/$short_version/

remove_ei_executable
