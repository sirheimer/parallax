#!/bin/bash
# Test script for Parallax with Legacy GPU Support
# This script helps you test a 3-GPU setup with legacy NVIDIA GPUs (1080 Ti and later)

echo "===================================="
echo "Parallax Legacy GPU Test Setup"
echo "===================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the correct directory
if [ ! -f "pyproject.toml" ]; then
    echo -e "${RED}Error: Please run this script from the parallax root directory${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Checking GPU availability...${NC}"
python3 << 'EOF'
import torch
if torch.cuda.is_available():
    print(f"✓ CUDA is available")
    print(f"✓ Found {torch.cuda.device_count()} GPU(s)")
    for i in range(torch.cuda.device_count()):
        props = torch.cuda.get_device_properties(i)
        vram_gb = props.total_memory / (1024**3)
        print(f"  GPU {i}: {props.name} ({vram_gb:.1f} GB VRAM)")
else:
    print("✗ CUDA is not available. Please install CUDA-enabled PyTorch.")
    exit(1)
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}GPU check failed. Please ensure CUDA is properly installed.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 2: Recommended Model Selection${NC}"
echo ""
echo "For testing with legacy GPUs (especially GTX 1060-1080 Ti), we recommend:"
echo "  • Qwen/Qwen2.5-0.5B-Instruct (smallest, ~1GB per shard)"
echo "  • Qwen/Qwen2.5-1.5B-Instruct (small, ~2GB per shard)"
echo "  • Qwen/Qwen2.5-3B-Instruct (medium, ~3-4GB per shard with INT8)"
echo "  • mlx-community/Phi-3-mini-4k-instruct-4bit (quantized, ~2GB per shard)"
echo ""
echo "For RTX 2070 and above, you can try:"
echo "  • Qwen/Qwen2.5-7B-Instruct-GPTQ-Int4 (quantized 7B model)"
echo "  • meta-llama/Llama-3.2-3B-Instruct"
echo ""

read -p "Enter model name (or press Enter for default Qwen/Qwen2.5-1.5B-Instruct): " MODEL_NAME
MODEL_NAME=${MODEL_NAME:-"Qwen/Qwen2.5-1.5B-Instruct"}

echo ""
echo -e "${YELLOW}Step 3: Starting Parallax Scheduler${NC}"
echo "This will start the scheduler with frontend on port 3001"
echo ""
echo "Run this command in a NEW TERMINAL WINDOW:"
echo ""
echo -e "${GREEN}parallax run -m ${MODEL_NAME} -n 3 --host 0.0.0.0${NC}"
echo ""
echo "Then open http://localhost:3001 in your browser to access the web UI"
echo ""

read -p "Press Enter when scheduler is running..."

echo ""
echo -e "${YELLOW}Step 4: Joining Nodes with Legacy GPU Support${NC}"
echo ""
echo "Now you need to join your 3 GPUs to the cluster."
echo ""
echo "On EACH Windows PC with a GPU, run:"
echo ""
echo -e "${GREEN}parallax join --legacy-gpu${NC}"
echo ""
echo "If on a remote network, you'll need the scheduler address:"
echo -e "${GREEN}parallax join --legacy-gpu -s <scheduler-peer-id>${NC}"
echo ""
echo "The scheduler peer ID can be found in the scheduler terminal output."
echo ""
echo "Expected behavior:"
echo "  • Legacy GPU mode will automatically use torch_native attention"
echo "  • Batch size will be reduced to 4 for better stability"
echo "  • Older GPUs (1080 Ti, etc.) will be detected with correct specs"
echo ""
echo "Watch the scheduler web UI at http://localhost:3001 to see nodes joining!"
echo ""

read -p "Press Enter when all 3 nodes have joined..."

echo ""
echo -e "${YELLOW}Step 5: Testing Inference${NC}"
echo ""
echo "You can now test inference in two ways:"
echo ""
echo "1. Use the web UI at http://localhost:3001"
echo "   - Navigate to the chat interface"
echo "   - Send a test message"
echo "   - Observe the response being generated across your GPUs"
echo ""
echo "2. Use curl to test the API:"
echo ""
cat << 'CURL_CMD'
curl --location 'http://localhost:3001/v1/chat/completions' \
  --header 'Content-Type: application/json' \
  --data '{
    "max_tokens": 100,
    "messages": [
      {
        "role": "user",
        "content": "Tell me about distributed computing in one sentence."
      }
    ],
    "stream": true
  }'
CURL_CMD

echo ""
echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Troubleshooting tips:"
echo "  • If nodes fail to connect, check firewall settings"
echo "  • If you see CUDA errors, verify CUDA version compatibility"
echo "  • For low VRAM GPUs (6GB), consider using smaller models"
echo "  • Check logs for 'Legacy GPU mode enabled' confirmation"
echo "  • Monitor GPU memory with: nvidia-smi"
echo ""
echo "===================================="

