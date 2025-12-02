# 🧪 Testing Your Legacy GPU Implementation

## What You Need to Test

You've successfully implemented legacy GPU support! Here's exactly what you need to run to test it.

---

## 🖥️ Setup Requirements

### Your Hardware
- **3 Windows PCs** with NVIDIA GPUs (1080 Ti or newer)
- All on the **same network** (or set up for relay mode)
- Each PC should have **6GB+ VRAM**

### Software Prerequisites on Each PC
```powershell
# 1. Check Python version (must be 3.11-3.13)
python --version

# 2. Check CUDA is working
nvidia-smi

# 3. Install Parallax (in the project directory)
cd parallax
pip install -e .\[gpu]

# 4. Verify installation
parallax --help
```

---

## 🚀 Test Procedure

### PC #1: Scheduler (Your Main PC)

**Step 1**: Open PowerShell as Administrator

**Step 2**: Start the scheduler with a small model:
```powershell
parallax run -m Qwen/Qwen2.5-1.5B-Instruct -n 3 --host 0.0.0.0
```

**Step 3**: Wait for this output:
```
✓ Scheduler started on port 3001
✓ Web UI available at http://localhost:3001
✓ Scheduler peer ID: 12D3KooW... [COPY THIS!]
```

**Step 4**: Open browser to `http://localhost:3001` - you should see the Parallax UI

---

### PC #2 & #3: Worker Nodes

On **EACH** of your other PCs (including PC #1 if it has a GPU):

**Step 1**: Open PowerShell as Administrator

**Step 2**: Run the join command with legacy GPU support:

**Option A - Same Network (LAN)**:
```powershell
parallax join --legacy-gpu
```

**Option B - Remote/Different Network**:
```powershell
parallax join --legacy-gpu -s 12D3KooW...
```
(Use the scheduler peer ID from PC #1)

**Step 3**: Look for this in the output:
```
INFO - Legacy GPU mode enabled - using torch_native attention backend
INFO - Reduced max_batch_size to 4 for legacy GPU compatibility
INFO - Detected GPU: NVIDIA GeForce GTX 1080 Ti (11.0 GB VRAM)
INFO - Joining cluster...
```

**Step 4**: Wait for:
```
INFO - Successfully joined! Assigned layers [X, Y)
```

---

## ✅ Verification Checklist

### In the Web UI (http://localhost:3001)
- [ ] All 3 nodes show as "READY"
- [ ] Each node shows its assigned layer range (e.g., [0,8), [8,16), [16,24))
- [ ] GPU model names are displayed correctly

### In PowerShell Logs
- [ ] See "Legacy GPU mode enabled" on all worker nodes
- [ ] No red ERROR messages
- [ ] Layer allocation makes sense (adds up to total model layers)

### GPU Monitoring (run on each PC)
```powershell
nvidia-smi
```
- [ ] GPU memory is allocated (~2-4GB per node for this model)
- [ ] GPU utilization shows activity during inference

---

## 🎯 Test Inference

### Test #1: Web UI Chat
1. Click to chat interface in web UI
2. Type: "What is 2+2?"
3. Hit send
4. **Expected**: Response generates (might take a few seconds)

### Test #2: API Call
In PowerShell on scheduler PC:
```powershell
curl http://localhost:3001/v1/chat/completions `
  -H "Content-Type: application/json" `
  -d '{\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}],\"max_tokens\":50,\"stream\":true}'
```

**Expected**: Stream of tokens returned

---

## 🐛 Common Issues & Quick Fixes

### Issue: "parallax: command not found"
**Fix**:
```powershell
pip install -e .\[gpu]
# Then restart PowerShell
```

### Issue: "Legacy GPU mode enabled" NOT appearing
**Fix**: You forgot the `--legacy-gpu` flag! Add it:
```powershell
parallax join --legacy-gpu
```

### Issue: "CUDA out of memory"
**Fix #1** - Use smaller model:
```powershell
# On scheduler PC, restart with:
parallax run -m Qwen/Qwen2.5-0.5B-Instruct -n 3
```

**Fix #2** - Reduce batch size:
```powershell
parallax join --legacy-gpu --max-batch-size 2
```

### Issue: Nodes not connecting
**Fix**: Check Windows Firewall, or use relay mode:
```powershell
parallax join --legacy-gpu --use-relay
```

### Issue: Very slow (>10 seconds per token)
**Check**:
1. Are other programs using the GPU? Close them
2. Is network lagging? `ping` between PCs
3. Is GPU actually being used? Check `nvidia-smi`

---

## 📊 Expected Results

### Performance Benchmarks

For **Qwen2.5-1.5B-Instruct** on 3 GPUs:

| Your Setup | Tokens/sec | First Token Latency |
|------------|-----------|---------------------|
| 3x RTX 3080 | ~40-50 | 200-300ms |
| 3x RTX 2080 | ~25-35 | 300-500ms |
| 3x GTX 1080 Ti | ~15-20 | 500-800ms |
| Mixed (1060+3070+3070) | ~20-30 | 400-600ms |

**Note**: These are rough estimates. Your mileage may vary.

### What Success Looks Like

**Console Output**:
```
INFO - Legacy GPU mode enabled - using torch_native attention backend
INFO - Reduced max_batch_size to 4 for legacy GPU compatibility
INFO - Detected GPU: NVIDIA GeForce GTX 1080 Ti (11.0 GB VRAM)
INFO - Successfully joined! Assigned layers [0, 8)
INFO - Node status: READY
INFO - Received request req-123
INFO - Dispatched request via path [node1, node2, node3]
```

**Web UI**:
- Green "READY" status on all nodes
- Chat interface generates responses
- No error messages

**GPU Monitoring** (nvidia-smi):
- Memory usage: 2-4GB per GPU
- GPU utilization: 30-80% during inference
- Temperature: 50-75°C

---

## 🎓 Understanding Your Results

### Layer Distribution
The scheduler automatically distributes layers based on GPU capabilities:

Example with 3 GPUs (24 total layers):
- **GPU 1** (1060, 6GB): Layers 0-7 (8 layers)
- **GPU 2** (3070, 8GB): Layers 8-16 (8 layers)
- **GPU 3** (3070, 8GB): Layers 16-24 (8 layers)

### Pipeline Flow
Your request flows: GPU1 → GPU2 → GPU3 → Response

Each GPU:
1. Receives hidden states from previous GPU
2. Processes through its assigned layers
3. Sends hidden states to next GPU
4. GPU3 generates final tokens

### Why It's Slower Than Single GPU
- **Network latency**: Data transfer between GPUs
- **Sequential processing**: Each GPU waits for previous
- **Legacy backend**: torch_native is slower than flashinfer

But you can run **bigger models** than any single GPU!

---

## 📸 Screenshots to Take

Capture these for your records:

1. **nvidia-smi** output on all 3 PCs
2. **Web UI** showing all nodes READY
3. **Chat interface** with a generated response
4. **PowerShell logs** showing "Legacy GPU mode enabled"

---

## 🎉 Success Criteria

You've successfully implemented and tested if:

✅ All 3 nodes connect and show READY
✅ Logs show "Legacy GPU mode enabled" on all workers  
✅ Layer allocations are displayed (and add up correctly)
✅ Chat interface generates responses
✅ GPU memory is being used (visible in nvidia-smi)
✅ No CUDA errors in logs
✅ Responses are coherent (not gibberish)

---

## 📝 Next Steps After Testing

Once basic testing works:

### 1. Try Different Models
```powershell
# Larger model (if you have 8GB+ VRAM)
parallax run -m Qwen/Qwen2.5-3B-Instruct -n 3

# Quantized model (better for 6GB GPUs)
parallax run -m Qwen/Qwen2.5-3B-Instruct-GPTQ-Int4 -n 3
```

### 2. Optimize Performance
```powershell
# Increase batch size if you have headroom
parallax join --legacy-gpu --max-batch-size 6

# Increase sequence length for longer conversations
parallax join --legacy-gpu --max-sequence-length 4096
```

### 3. Test with More Nodes
```powershell
# 5 nodes for better parallelism
parallax run -m Qwen/Qwen2.5-7B-Instruct -n 5
```

### 4. Benchmark Performance
Use the benchmark script:
```powershell
python src/backend/benchmark/benchmark_serving.py `
  --base-url http://localhost:3001 `
  --model Qwen/Qwen2.5-1.5B-Instruct `
  --num-prompts 10
```

---

## 🆘 If All Else Fails

### Debug Mode
Run with detailed logging:
```powershell
# Scheduler
parallax run -m Qwen/Qwen2.5-1.5B-Instruct -n 3 --log-level DEBUG

# Worker
parallax join --legacy-gpu --log-level DEBUG
```

### Minimal Test
Start with absolute minimum:
```powershell
# Tiny model, 2 nodes
parallax run -m Qwen/Qwen2.5-0.5B-Instruct -n 2

# Join with maximum compatibility
parallax join --legacy-gpu --max-batch-size 1 --max-sequence-length 512
```

### Get Help
- Check logs in detail
- Read `LEGACY_GPU_SETUP.md` for troubleshooting
- Ask on Discord with:
  - GPU models
  - Error messages
  - Full logs with --log-level DEBUG

---

## 🏆 You're Ready!

**Everything is set up and documented.**

All you need to do now is:
1. Run the scheduler
2. Join 3 nodes with `--legacy-gpu`
3. Send a test message
4. Celebrate! 🎉

**Good luck with your testing!** You've built something awesome - a decentralized GPU cluster that works with older hardware. That's the foundation of your B2B marketplace! 🚀

