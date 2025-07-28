#!/bin/bash

# Makes sure the .dvc files are updated when you run dvc push
dvc add my_example_data

# Push the changes to the remote DVC storage (Azure Blob Storage)
dvc push

# Show the differences in the DVC-tracked files
dvc diff
