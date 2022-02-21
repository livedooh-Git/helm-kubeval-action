#!/bin/sh -l

# Exit on error.
set -e;

CURRENT_DIR=$(pwd);

run_kubeval() {
    # Validate all generated manifest against Kubernetes json schema
    cd "$1"
    VALUES_FILE="$2"
    mkdir helm-output;
    set -e;
    helm template --values "$VALUES_FILE" --output-dir helm-output .;
    find helm-output -type f -exec \
        /kubeval/kubeval \
            "-o=$OUTPUT" \
            "--strict=$STRICT" \
            "--kubernetes-version=$KUBERNETES_VERSION" \
            "--openshift=$OPENSHIFT" \
            "--ignore-missing-schemas=$IGNORE_MISSING_SCHEMAS" \
        {} +; 
    rm -rf helm-output;
}

# For all charts (i.e for every directory) in the directory
for CHART in "$CHARTS_PATH"/*/; do
    cd "$CURRENT_DIR/$CHART";
    
    for VALUES_FILE in values-app*.yaml; do
        RESULT=$(run_kubeval "$(pwd)" "$VALUES_FILE");
        echo "$RESULT" | grep -Ev '^PASS|^wrote|^\w+? - Set' | awk 'NF';
        errorMatchCount=$(echo "$RESULT" | grep -E '^ERR|^Error|invalid|nil' | wc -c);
        if [[ $errorMatchCount -gt 0 ]]
        then
            exit 1;
        fi
    done
done

