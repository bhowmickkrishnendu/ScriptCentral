# SonarQube Installation Notes and Error Fix

## Common Error

You may encounter the following error when starting SonarQube:

    error
    bootstrap check failure [1] of [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]

## Solution

Increase the virtual memory areas by running:

    echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

## Docker Compose Commands

To stop and remove existing containers and volumes:

    docker-compose down -v

To recreate and start the containers:

    docker-compose up -d
