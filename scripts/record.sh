#!/bin/bash

# ======================
# Default settings
# ======================
HF_ID="<jamietherobot>"
FOLLOWER_PORT="/dev/ttyACM_follower"
LEADER_PORT="/dev/ttyACM_leader"
NUM_EPISODES=50

# cam_external and cam_wrist are used as SmolVLA feature keys — must stay consistent
# camera setting variables
CAM_EXTERNAL='{"type": "opencv", "index_or_path": "/dev/v4l/by-id/usb-046d_C270_HD_WEBCAM_200901010001-video-index0", "fps": 30, "width": 640, "height": 480}'
CAM_WRIST='{"type": "opencv", "index_or_path": "/dev/v4l/by-id/usb-icSpring_icspring_camera-video-index0", "fps": 30, "width": 640, "height": 480}'

CAM_CONFIG="{\"cam_external\": $CAM_EXTERNAL, \"cam_wrist\": $CAM_WRIST}"


# ======================
# Argument parsing
# ======================
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --task)
            TASK="$2"
            shift 2
            ;;
        --episodes)
            NUM_EPISODES="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true    # dry-run flag
            shift 1
            ;;
        *)
            echo "argument not recognized: $1"
            exit 1
            ;;
    esac
done

# ================================
# Validate required arguments
# ================================
if [[ -z "$TASK" ]]; then
    echo "ERROR: --task argument needed"
    echo "usage: bash record.sh --task [water|meds|btn]"
    exit 1
fi

# ======================
# Task configuration
# ======================
case "$TASK" in
    water)
        SINGLE_TASK="pick and place water bottle"
        DATASET_REPO="$HF_ID/pnp_water"
        ;;
    meds)
        SINGLE_TASK="pick and place medicine bottle"
        DATASET_REPO="$HF_ID/pnp_meds"
        ;;
    btn)
        SINGLE_TASK="press emergency button"
        DATASET_REPO="$HF_ID/press_btn"
        NUM_EPISODES=30
        ;;
    *)
        echo "Unknown task: $TASK. Choose from water / meds / btn"
        exit 1
        ;;
esac

# ======================
# Pre-run summary
# ======================
echo "=============================="
echo "Task       : $TASK"            # Selected task
echo "Instruction: $SINGLE_TASK"     # Language instruction for SmolVLA
echo "Dataset    : $DATASET_REPO"    # Target HuggingFace dataset
echo "Episodes   : $NUM_EPISODES"    # Number of episodes to collect
echo "=============================="

# ======================
# Activate .venv
# ======================
source ~/hello_chores/.venv/bin/activate

# ======================
# Run lerobot-record
# ======================
if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] TASK=$TASK"
    echo "[DRY-RUN] SINGLE_TASK=$SINGLE_TASK"
    echo "[DRY-RUN] DATASET_REPO=$DATASET_REPO"
    echo "[DRY-RUN] NUM_EPISODES=$NUM_EPISODES"
    exit 0
fi

# Record only; push manually later
lerobot-record \
    --robot.type=so101_follower \
    --robot.port="$FOLLOWER_PORT" \
    --robot.id=follower_arm \
    --teleop.type=so101_leader \
    --teleop.port="$LEADER_PORT" \
    --teleop.id=leader_arm \
    --robot.cameras="$CAM_CONFIG" \
    --dataset.repo_id="$DATASET_REPO" \
    --dataset.single_task="$SINGLE_TASK" \
    --dataset.num_episodes="$NUM_EPISODES" \
    --dataset.push_to_hub=false