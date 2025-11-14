#!/bin/bash

echo "Starting documentation server..."
echo ""

python3 -m http.server --directory docs
