# Legacy GPU Support for Parallax

This guide explains how to use Parallax with older NVIDIA GPUs (GTX 10-series, RTX 20-series, and RTX 30-series).

## 🎯 Overview

Parallax now supports legacy GPUs through a compatibility mode that:
- ✅ Works with GTX 1060, 1070, 1080, 1080 Ti and later
- ✅ Automatically switches to `torch_native` attention backend
- ✅ Optimizes batch sizes for older hardware
- ✅ Properly detects hardware specs for optimal layer allocation

## 📋 Supported GPUs

### Minimum Requirements
- **GPU**: NVIDIA GTX 1080 Ti or newer
- **VRAM**: 6GB minimum (8GB+ recommended)
- **CUDA**: CUDA 10.0+ with appropriate drivers
- **Compute Capability**: 6.1+ (Pascal architecture and later)

### Tested GPU Models

| GPU Series | Models | VRAM | Recommended Use Case |
|------------|--------|------|---------------------|
| **GTX 10-series** | 1080 Ti, 1080, 1070 Ti, 1070, 1060 | 6-11GB | Small models (1.5-3B params) |
| **RTX 20-series** | 2080 Ti, 2080 Super, 2080, 2070 Super, 2070, 2060 | 6-11GB | Medium models (3-7B params) |
| **RTX 30-series** | 3090 Ti, 3090, 3080 Ti, 3080, 3070 Ti, 3070, 3060 Ti, 3060 | 8-24GB | Large models (7B+ params) |
| **RTX 40-series** | 4090, 4080, 4070 Ti, 4070, 4060 Ti, 4060 | 8-24GB | Any model (optimal) |

## 🚀 Quick Start

### 1. Installation

First, ensure you have Parallax installed with GPU support:

```bash
# Clone the repository
git clone https://github.com/GradientHQ/parallax.git
cd parallax

# Install with GPU support
pip install -e '.[gpu]'
```

### 2. Start the Scheduler

On your main/coordinator machine:

```bash
# With frontend UI (recommended for testing)
parallax run -m Qwen/Qwen2.5-1.5B-Instruct -n 3 --host 0.0.0.0

# Or without frontend
parallax run -m Qwen/Qwen2.5-1.5B-Instruct -n 3
```

### 3. Join Nodes with Legacy GPU Flag

On each Windows PC with a legacy GPU:

```bash
# Local network (auto-discovery)
parallax join --legacy-gpu

# Remote network (specify scheduler)
parallax join --legacy-gpu -s <scheduler-peer-id>
```

**Important**: The `--legacy-gpu` flag:
- Switches attention backend to `torch_native` (compatible with older GPUs)
- Reduces default batch size from 8 to 4
- Works with all supported legacy GPUs

## 🎮 Recommended Models by GPU

### For 6GB VRAM (GTX 1060, RTX 2060)

Use small, quantized models:

```bash
# Ultra-small (perfect for testing)
parallax run -m Qwen/Qwen2.5-0.5B-Instruct -n 3

# Small but capable
parallax run -m Qwen/Qwen2.5-1.5B-Instruct -n 3

# Quantized 3B model
parallax run -m Qwen/Qwen2.5-3B-Instruct-GPTQ-Int4 -n 3
```

### For 8-11GB VRAM (GTX 1080 Ti, RTX 2070-2080 Ti, RTX 3060-3070)

Use medium models or quantized large models:

```bash
# 3B model (good balance)
parallax run -m Qwen/Qwen2.5-3B-Instruct -n 3

# Quantized 7B model
parallax run -m Qwen/Qwen2.5-7B-Instruct-GPTQ-Int4 -n 3

# Phi-3 (efficient architecture)
parallax run -m microsoft/Phi-3-mini-4k-instruct -n 3
```

### For 12GB+ VRAM (RTX 3080 and above)

Use full-size models:

```bash
# Full 7B model
parallax run -m Qwen/Qwen2.5-7B-Instruct -n 3

# Llama 3.2
parallax run -m meta-llama/Llama-3.2-3B-Instruct -n 3
```

## 🔧 Advanced Configuration

### Manual Configuration (Without --legacy-gpu Flag)

If you want more control, you can manually specify settings:

```bash
parallax join \
  --attention-backend torch_native \
  --max-batch-size 4 \
  --max-sequence-length 2048 \
  --kvcache-mem-ratio 0.3 \
  -s <scheduler-peer-id>
```

### Performance Tuning for Legacy GPUs

#### Low VRAM (6GB)
```bash
parallax join --legacy-gpu \
  --max-batch-size 2 \
  --max-sequence-length 1024 \
  --kvcache-mem-ratio 0.25
```

#### Medium VRAM (8-11GB)
```bash
parallax join --legacy-gpu \
  --max-batch-size 4 \
  --max-sequence-length 2048 \
  --kvcache-mem-ratio 0.3
```

#### High VRAM (12GB+)
```bash
parallax join --legacy-gpu \
  --max-batch-size 8 \
  --max-sequence-length 4096 \
  --kvcache-mem-ratio 0.35
```

## 📊 Expected Performance

Performance varies significantly by GPU generation:

| GPU | Relative Speed | Tokens/sec (7B model) | Viable for Production? |
|-----|----------------|----------------------|------------------------|
| RTX 4090 | 100% (baseline) | ~80-100 | ✅ Excellent |
| RTX 3080 | ~60% | ~50-60 | ✅ Good |
| RTX 2080 Ti | ~40% | ~30-40 | ✅ Acceptable |
| GTX 1080 Ti | ~20% | ~15-20 | ⚠️ Limited |
| GTX 1060 | ~10% | ~8-10 | ⚠️ Testing only |

**Note**: These numbers are approximate and depend on:
- Model size and architecture
- Batch size and sequence length
- Number of nodes in pipeline
- Network latency between nodes

## 🐛 Troubleshooting

### Issue: "CUDA out of memory"

**Solutions**:
1. Use a smaller model
2. Reduce batch size: `--max-batch-size 2`
3. Reduce sequence length: `--max-sequence-length 1024`
4. Lower KV cache ratio: `--kvcache-mem-ratio 0.2`

### Issue: "FlashInfer not supported on this GPU"

**Solution**: You forgot the `--legacy-gpu` flag! Add it to your join command:
```bash
parallax join --legacy-gpu
```

### Issue: Slow inference speed

**Expected behavior**: Legacy GPUs are slower than modern ones. However, if speed is unacceptably slow:

1. Check you're not running other GPU-intensive applications
2. Verify you're using the correct CUDA version for your GPU
3. Consider using a quantized model (INT4/INT8)
4. Monitor GPU utilization with `nvidia-smi`

### Issue: Nodes not connecting

**Solutions**:
1. Check firewall settings (allow ports 3000-3002, plus dynamic Lattica ports)
2. Verify all nodes can ping each other
3. Use `--use-relay` flag for NAT traversal:
   ```bash
   parallax join --legacy-gpu --use-relay
   ```

### Issue: Model download fails

**Solution**: Pre-download the model:
```bash
huggingface-cli download Qwen/Qwen2.5-1.5B-Instruct
```

## 🔍 Verification

### Check if Legacy Mode is Active

Look for these log messages when starting a node:

```
INFO - Legacy GPU mode enabled - using torch_native attention backend
INFO - Reduced max_batch_size to 4 for legacy GPU compatibility
```

### Monitor GPU Usage

On Windows:
```cmd
nvidia-smi -l 1
```

On Linux:
```bash
watch -n 1 nvidia-smi
```

### Test Inference

```bash
curl --location 'http://localhost:3001/v1/chat/completions' \
  --header 'Content-Type: application/json' \
  --data '{
    "max_tokens": 50,
    "messages": [
      {"role": "user", "content": "Say hello!"}
    ],
    "stream": true
  }'
```

## 💡 Best Practices

### 1. Start Small
Begin with the smallest model (Qwen2.5-0.5B) to verify your setup works before scaling up.

### 2. Mix GPU Generations Strategically
Place the slowest GPU at the beginning or end of the pipeline, not in the middle:
- **Good**: [1060] → [3080] → [3080]
- **Bad**: [3080] → [1060] → [3080]

### 3. Monitor Temperature
Legacy GPUs may run hotter during sustained inference. Keep an eye on temperatures:
```bash
nvidia-smi --query-gpu=temperature.gpu --format=csv
```

### 4. Use Quantized Models
For legacy GPUs, quantized models (INT4/INT8) provide the best performance-to-memory ratio.

### 5. Network Matters
With legacy GPUs, network latency becomes more noticeable. Use gigabit ethernet or better.

## 📚 Technical Details

### What Changed?

#### Attention Backend
- **Default**: FlashInfer (requires Compute Capability 8.0+)
- **Legacy**: torch_native (works on any CUDA GPU)
- **Performance impact**: ~30-40% slower but fully compatible

#### Hardware Detection
Added specs for 30+ GPU models from GTX 1060 to RTX 4090, including:
- FP16 TFLOPS
- Memory bandwidth
- Optimal batch sizes

#### Automatic Optimization
When `--legacy-gpu` is used:
- Attention backend → torch_native
- Max batch size → 4 (if default was 8)
- Appropriate memory management for lower-end hardware

## 🤝 Contributing

Found a bug or want to add support for more GPUs? Please:
1. Open an issue on GitHub
2. Include your GPU model and specs
3. Provide logs with `--log-level DEBUG`

## 📞 Support

For issues specific to legacy GPU support:
- Discord: https://discord.gg/parallax
- GitHub Issues: Tag with `legacy-gpu` label

---

**Happy distributed inference!** 🚀

