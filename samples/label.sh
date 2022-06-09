#!/bin/bash

# This sample script adds a label to each GitHub repository.

gh label create security -f --description "Security-Related" --color "#0000FF"

sleep 2s