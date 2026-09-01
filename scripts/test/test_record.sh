#!/bin/bash
# Test script for record.sh

SCRIPT="$(dirname "$0")/../record.sh"
PASS=0
FAIL=0

# ======================
# Helper function
# ======================
run_test(){
    local TEST_NAME="$1"
    local EXPECTED="$2"
    local TYPE="$3"
    shift 3

    OUTPUT=$(bash "$SCRIPT" "$@" 2>&1)
    EXIT_CODE=$?

    if [[ "$TYPE" == "exit_code" ]]; then
        if [[ "$EXIT_CODE" == "$EXPECTED" ]]; then
            echo "PASS: $TEST_NAME"
            ((PASS++))
        else
            echo "FAIL: $TEST_NAME (expected exit $EXPECTED, got $EXIT_CODE)"
            ((FAIL++))
        fi
    elif [[ "$TYPE" == "output" ]]; then
        if echo "$OUTPUT" | grep -q "$EXPECTED"; then
            echo "PASS: $TEST_NAME"
            ((PASS++))
        else
            echo "FAIL: $TEST_NAME (expected '$EXPECTED' in output)"
            echo "      actual output: $OUTPUT"
            ((FAIL++))
        fi
    fi
}

# ======================
# Test cases
# ======================

# TC1: without --task command -> exit 1
run_test "TC1: missing --task" 1 "exit_code"

# TC2: wrong task value -> exit 1
run_test "TC2: invalid task value" 1 "exit_code" \
    --task invalid_task

# TC3: unknown argument -> exit 1
run_test "TC3: unknown argument" 1 "exit_code" \
    --task water --unknown-arg

# TC4: --task water -> check if DATASET_REPO has pnp_water
run_test "TC4: water dataset repo" "pnp_water" "output" \
    --task water --dry-run

# TC5: --task meds -> check if DATASET_REPO has pnp_meds
run_test "TC5: medicine dataset repo" "pnp_meds" "output" \
    --task meds --dry-run

# TC6: --task btn -> NUM_EPISODES should be overridden to 30
run_test "TC6: btn episodes override" "NUM_EPISODES=30" "output" \
    --task btn --dry-run

# TC7: check if episodes override NUM_EPISODES
run_test "TC7: --episodes override" "NUM_EPISODES=20" "output" \
    --task water --episodes 20 --dry-run

# ======================
# Summary
# ======================
echo "=============================="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "=============================="