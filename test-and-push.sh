#!/bin/bash
set -e

mkdir -p tmp_public
echo "<?php phpinfo(); ?>" > tmp_public/index.php

# Test function
test_image() {
    local flavor=$1
    local mode=$2
    local tag="test-$flavor-$mode"
    local dockerfile="flavors/vanilla/$mode/Dockerfile"
    local build_arg=""
    
    if [ "$flavor" == "phalcon" ]; then
        build_arg="--build-arg BUILD_FLAVOR=-phalcon"
    fi
    
    echo "Building $tag from $dockerfile..."
    docker build $build_arg -f "$dockerfile" -t "$tag" .
    
    echo "Running $tag..."
    local container_id
    if [ "$mode" == "prod" ]; then
        container_id=$(docker run -d -e MYSQL_ROOT_PASSWORD=secret -v $(pwd)/tmp_public:/app/public "$tag")
    else
        container_id=$(docker run -d -v $(pwd)/tmp_public:/app/public "$tag")
    fi
    
    echo "Waiting for healthcheck..."
    # Wait up to 60 seconds
    local healthy=0
    for i in {1..60}; do
        local health_status=$(docker inspect --format='{{json .State.Health.Status}}' "$container_id" | tr -d '"')
        if [ "$health_status" == "healthy" ]; then
            healthy=1
            break
        elif [ "$health_status" == "unhealthy" ]; then
            echo "Container $container_id became unhealthy!"
            docker logs "$container_id"
            docker stop "$container_id" || true
            docker rm "$container_id" || true
            return 1
        fi
        sleep 2
    done
    
    if [ $healthy -eq 1 ]; then
        echo "$tag is healthy!"
    else
        echo "$tag failed to become healthy in time."
        docker logs "$container_id"
        docker stop "$container_id" || true
        docker rm "$container_id" || true
        return 1
    fi
    
    echo "Cleaning up $tag..."
    docker stop "$container_id"
    docker rm "$container_id"
}

# Run tests
test_image "phalcon" "prod"
test_image "phalcon" "dev"

echo "All tests passed!"
rm -rf tmp_public

# Commit and push
echo "Committing and pushing changes..."
git add .
git commit -m "chore: translate AGENTS.md, fix apt update, fix phalcon prod symlink"
env -u GITHUB_TOKEN -u GH_TOKEN git push

echo "Done!"
