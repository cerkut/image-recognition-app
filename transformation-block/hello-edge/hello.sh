#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Parse arguments
NAME="World"

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --name)
        NAME="$2"
        shift # past argument
        shift # past value
        ;;
        *)
        shift # past argument
        ;;
    esac
done

echo "Hello, $NAME!"
echo "Transformation block executed successfully."
