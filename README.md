# 팀명 - RBNO

# 👋 Hello, Chores!
## ROS2 기반 음성 인터페이스 생활 보조 로봇

> 거동이 불편한 사용자가 음성만으로 물품을 요청하고 도움을 요청할 수 있는 ROS2 기반 생활 보조 로봇 시스템. SmolVLA, ROS2, SO-ARM101 로봇 암으로 구동된다.

---

## 📌 Table of Contents

- [Project Overview](#-project-overview)
- [High-Level Design](#-high-level-design)
- [Key Features & Implementation](#-key-features--implementation)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Environment Setup](#-environment-setup)
- [Steps to Build](#-steps-to-build)
- [Steps to Run](#-steps-to-run)
- [Future Work](#-future-work)
- [Team](#-team)
- [Appendix](#-appendix)

---

## 🔍 Project Overview

**Hello, Chores!** 는 거동이 불편한 사용자를 위한 ROS2 기반 생활 보조 로봇 시스템이다.

사용자는 음성만으로 로봇에게 도움을 요청할 수 있다. 시스템이 음성을 인식하고 의도를 분류한 뒤, SO-ARM101 로봇 암이 물품을 집어 전달하거나, 비상 버튼을 눌러 보호자나 119에 도움을 요청하는 물리적 동작을 수행한다.

```
Voice → STT → Intent Classification → SmolVLA → ROS2 → Robot Action
```

---

## ✏ High-Level Design

### Architecture Diagram

![Architecture Diagram](https://media.discordapp.net/attachments/1522069303057453116/1543230327806361610/hello_chores_diagram.png?ex=6a941cbd&is=6a92cb3d&hm=c40c8ea42c4da3c5d99ebfe150fa66bddecc221e1705cc352d10f93d1e5286b4&=&format=webp&quality=lossless&width=512&height=768)

### Why ROS2?

- **Safety Interrupt**: ROS2 Action Cancel은 SmolVLA 추론 지연과 완전히 독립적으로 동작한다. `safety_node`가 STOP 인텐트를 감지하는 즉시 미들웨어 수준에서 모터 제어 명령을 차단할 수 있어, AI 추론이 완료될 때까지 기다릴 필요가 없다.
- **신뢰성 있는 노드 간 통신**: ROS2의 DDS 기반 통신은 토픽·액션 단위로 노드를 명확히 분리하고, 각 노드의 생사 여부를 독립적으로 관리할 수 있다.
- **확장성**: 향후 더 많은 센서, 로봇 암, 또는 이동 플랫폼(모바일 베이스)을 추가할 때 기존 노드 구조를 그대로 유지하면서 확장할 수 있다.

---

## 🔑 Key Features & Implementation

### 1. Voice Pipeline
- 마이크 입력 → Whisper STT → 텍스트 변환
- LLM 기반 Intent Classifier가 `FETCH_OBJECT` · `HELP_REQUEST` · `STOP` 중 하나를 출력한다

### 2. SmolVLA Inference Server
- Fine-tuned SmolVLA (~450M params)를 INT8 양자화로 로드
- 입력: 탑뷰 카메라 프레임 + Wrist 카메라 프레임 + 언어 명령
- 출력: 관절 각도 시퀀스 → 로컬 IPC를 통해 `smolvla_node`로 전달
- ROS2 노드가 아닌 별도 Python 프로세스로 실행

### 3. ROS2 Control Layer
- `smolvla_node`: 관절 각도 수신 → 안전 범위 검증 → `feetech_driver_node`로 ROS2 Action Goal 전송
- `feetech_driver_node`: Feetech SDK 래핑, 모터 6개 제어, `/joint_states` 퍼블리시, `/so_arm101/joint_goal` 구독
- `safety_node`: 상시 감지, STOP 인텐트 수신 즉시 Action Cancel 발송 (SmolVLA 우회)

### 4. Help Request Flow
- `HELP_REQUEST` 인텐트 → SmolVLA가 버튼 누르기 궤적 추론 → SO-ARM101이 45mm 푸시버튼을 물리적으로 누름
- Arduino가 버튼 상태 변화 감지 (INPUT_PULLUP, NO 접점) → LED 즉시 작동
- Serial 신호 → Python 프로세스 → Twilio SMS 보호자 / 119 알림 (직접 전화하기 어려운 상황을 대체)

### 5. Training Pipeline
- 데이터 수집: LeRobot으로 Leader-Follower 원격 조종, 듀얼 카메라 동시 녹화 (cam_external + cam_wrist)
- Fine-tuning: RunPod GPU에서 SmolVLA LoRA 파인튜닝, 데이터셋과 체크포인트는 HuggingFace Hub으로 관리
- 추론: Fine-tuned 모델을 로컬 머신에 pull하여 데모 영상 녹화

---

## 💻 Tech Stack

| Layer | Technology |
|---|---|
| Robot | SO-ARM101 (Leader + Follower) |
| Robot Middleware | ROS2 Jazzy |
| Robot Driver | Feetech SDK (`feetech_driver_node`) |
| VLA Model | SmolVLA (~450M params, LoRA fine-tuned) |
| Data Collection | LeRobot |
| STT | OpenAI Whisper |
| Intent Classification | LLM (Python process) |
| Notification | Arduino + LED + Twilio SMS API |
| Vision | OpenCV (dual USB cameras) |
| Training Infrastructure | RunPod (GPU), HuggingFace Hub |
| Code Sync | GitHub |
| OS | Ubuntu 24.04 LTS |
| Language | Python |

---

## ✔ Prerequisites

- Ubuntu 24.04 LTS
- ROS2 Jazzy ([설치 가이드](https://docs.ros.org/en/jazzy/Installation.html))
- Python 3.10+
- SO-ARM101 로봇 암 + Feetech SDK
- USB 카메라 2대 (탑뷰 / Wrist)
- Arduino (USB 연결)
- HuggingFace Hub 계정 및 토큰
- Twilio 계정 및 SMS 서비스 설정

---

## ⚒ Steps to Build

```bash
# 1. ROS2 workspace로 이동
cd ~/ros2_ws

# 2. 의존성 설치
rosdep install --from-paths src --ignore-src -r -y

# 3. 빌드
colcon build

# 4. 환경 변수 설정
source install/setup.bash
```
---

## 🏃‍♂️ Steps to Run

실행 순서: ROS2 노드 → 추론 서버 → 메인 프로세스

**Terminal 1 — ROS2 노드 전체 실행**

```bash
cd ~/ros2_ws
source install/setup.bash
ros2 launch hello_chores_bringup hello_chores.launch.py
```

**Terminal 2 — SmolVLA 추론 서버 실행**

```bash
python3 ~/ros2_ws/src/smolvla_inference/inference_server.py
```

**Terminal 3 — 메인 Python 프로세스 실행 (STT + Intent + Twilio)**

```bash
python3 ~/ros2_ws/src/smolvla_inference/main.py
```

**설정 관련**

- `config/config.yaml`에서 카메라 포트, 모터 ID, 안전 범위, Arduino 포트를 머신 환경에 맞게 수정
- Arduino는 `hello_chores_arduino.ino`를 Arduino IDE로 업로드한 뒤 USB 연결 상태 유지
- 추론 서버 실행 전 HuggingFace Hub에서 모델 pull

---

## 🚀 Future Work

- Twilio SMS 보호자 알림 기능 고도화 (비상 연락처 다중 등록, 응답 확인)
- 대상 물품 종류 확대 및 임의 위치 일반화 성능 향상
- 웹 기반 모니터링 UI (로봇 상태, 카메라 피드, 인텐트 분류 결과 실시간 표시)
- 이동형 플랫폼(모바일 베이스)과의 통합

---

## 👨‍💻 Team

| 이름 | 담당 |
|---|---|
| [정다은](https://github.com/jamietherobot) | ROS2 노드 개발, 데이터 수집, SmolVLA 학습, 시스템 통합 전반 |
| [윤희나](https://github.com/heenanina) | Whisper STT, Intent Classification, Twilio SMS 구현 |

---

## 📑 Appendix

**참고 자료**

- [SO-ARM101 feetech_driver_node 구현 기준](https://wikidocs.net/384433)
- [ROS2 Jazzy 설치 가이드](https://docs.ros.org/en/jazzy/Installation.html)
- [LeRobot 공식 문서](https://github.com/huggingface/lerobot)
- [SmolVLA 모델 카드](https://huggingface.co/lerobot/smolvla_base)
- [Twilio SMS API 문서](https://www.twilio.com/docs/sms)




---

