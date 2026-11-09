#!/bin/bash
set -euo pipefail
nextflow run main.nf -resume "$@"