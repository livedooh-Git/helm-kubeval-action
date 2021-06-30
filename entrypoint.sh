#!/bin/sh -l

# Exit on error.
set -e;

CURRENT_DIR=$(pwd);

run_kubeval() {
    # Validate all generated manifest against Kubernetes json schema
    cd "$1"
    VALUES_FILE="$2"
    echo "Before mkdir";
    mkdir helm-output;
    echo "After mkdir";
    helm template --values "$VALUES_FILE" --output-dir helm-output . &>/dev/null;
    echo "Before find/kubeval";
    find helm-output -type f -exec \
        /kubeval/kubeval \
            "-o=$OUTPUT" \
            "--strict=$STRICT" \
            "--kubernetes-version=$KUBERNETES_VERSION" \
            "--openshift=$OPENSHIFT" \
            "--ignore-missing-schemas=$IGNORE_MISSING_SCHEMAS" \
        {} +;
    echo "After find/kubeval";
    echo "Before rm";
    rm -rf helm-output;
    echo "After rm";
}

# For all charts (i.e for every directory) in the directory
for CHART in "$CHARTS_PATH"/*/; do
    cd "$CURRENT_DIR/$CHART";

    for VALUES_FILE in values*.yaml; do
        run_kubeval "$(pwd)" "$VALUES_FILE" | grep -Ev "PASS|wrote|Set"
    done
done
