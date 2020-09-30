#!/bin/bash

while getopts ":f:d:n:" opt; do
  case $opt in
        f) FILE="$OPTARG"
        ;;
        d) DATASTORE="$OPTARG"
        ;;
        n) IMAGE_NAME="$OPTARG"
        ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

echo "File: $FILE"
echo "Datastore: $DATASTORE"
echo "Image Name: $IMAGE_NAME"

govc import.ova -ds=$DATASTORE \
    -name $IMAGE_NAME \
    $FILE
