# Quick Start: Testing Parallax with Legacy GPUs

## 🎯 Goal
Get Parallax running across 3 Windows PCs with older NVIDIA GPUs (1080 Ti or newer).

## 📝 Prerequisites Checklist

- [ ] 3 Windows PCs with NVIDIA GPUs (1080 Ti or newer)
- [ ] Python 3.11-3.13 installed on all PCs
- [ ] CUDA drivers installed (run `nvidia-smi` to verify)
- [ ] Parallax installed on all PCs (`pip install -e '.[gpu]'`)
- [ ] All PCs on the same network (or have relay setup for remote)

## 🚀 Step-by-Step Setup

### Step 1: Choose Your Scheduler PC

Pick your most powerful or most convenient PC to run the scheduler.

### Step 2: Start the Scheduler

**On the scheduler PC**, open PowerShell as Administrator and run:

```powershell
parallax run -m Qwen/Qwen2.5-1.5B-Instruct -n 3 --host 0.0.0.0
```

**What this does**:
- `-m Qwen/Qwen2.5-1.5B-Instruct` - Uses a small 1.5B model (good for testing)
- `-n 3` - Expects 3 worker nodes to join
- `--host 0.0.0.0` - Makes scheduler accessible from other PCs

**Expected output**:
```
✓ Scheduler started on port 3001
✓ Web UI available at http://localhost:3001
✓ Scheduler peer ID: 12D3KooW...
```

**Important**: Copy the scheduler peer ID - you'll need it for remote nodes!

### Step 3: Open the Web UI

On the scheduler PC, open a browser and go to:
```
http://localhost:3001
```

You should see the Parallax setup interface.

### Step 4: Join Each GPU Node

**On EACH of your 3 PCs** (including the scheduler PC if it has a GPU):

#### For Local Network (Same LAN):
```powershell
parallax join --legacy-gpu
```

#### For Remote Network:
```powershell
parallax join --legacy-gpu -s 12D3KooW...
```
(Replace `12D3KooW...` with the actual scheduler peer ID from Step 2)

**Expected output**:
```
INFO - Legacy GPU mode enabled - using torch_native attention backend
INFO - Reduced max_batch_size to 4 for legacy GPU compatibility
INFO - Detected GPU: NVIDIA GeForce GTX 1080 Ti (11.0 GB VRAM)
INFO - Joining cluster...
INFO - Successfully joined! Assigned layers [0, 8)
```

### Step 5: Wait for All Nodes

Watch the web UI - you should see nodes appearing with their status:
- **JOINING** → **INITIALIZING** → **READY**

Once all 3 nodes show **READY**, you're good to go!

### Step 6: Test Inference

#### Option A: Use the Web UI

1. Click to go to the chat interface
2. Type a message: "Tell me about distributed computing"
3. Hit send and watch the response generate

#### Option B: Use curl

```powershell
curl http://localhost:3001/v1/chat/completions `
  -H "Content-Type: application/json" `
  -d '{\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}],\"max_tokens\":50,\"stream\":true}'
```

## 🎉 Success!

If you see responses generating, congratulations! You've successfully distributed LLM inference across multiple legacy GPUs!

## 📊 What You've Achieved

Your 3 GPUs are now:
1. **Working together** as a pipeline
2. **Splitting the model** across layers
3. **Sharing the inference load** efficiently
4. **Compatible** despite being older hardware

## 🔍 Verification

To verify the setup is working correctly:

1. **Check GPU usage on each PC**:
   ```powershell
   nvidia-smi -l 1
   ```
   You should see GPU memory used and utilization % active during inference.

2. **Check node status in web UI**:
   - All nodes should show as "READY"
   - Layer allocations should be visible (e.g., [0,8), [8,16), [16,24))
   - Request count should increment when you send messages

3. **Monitor logs**:
   Look for these in the console output:
   ```
   ✓ Legacy GPU mode enabled
   ✓ Node joined successfully
   ✓ Dispatched request via path [node1, node2, node3]
   ```

## 🐛 Common Issues

### Issue: "parallax: command not found"

**Fix**: Ensure Parallax is installed and in PATH:
```powershell
pip install -e .\[gpu]
```

### Issue: Nodes won't connect

**Fix 1** - Check firewall:
- Allow Python through Windows Firewall
- Or temporarily disable firewall for testing

**Fix 2** - Use relay mode:
```powershell
parallax join --legacy-gpu --use-relay
```

### Issue: "CUDA out of memory"

**Fix 1** - Use smaller model:
```powershell
parallax run -m Qwen/Qwen2.5-0.5B-Instruct -n 3
```

**Fix 2** - Reduce batch size:
```powershell
parallax join --legacy-gpu --max-batch-size 2
```

### Issue: Very slow inference

**Expected**: Legacy GPUs are slower, but if it's unusably slow:
- Close other GPU applications
- Use a smaller model
- Check network latency between PCs (`ping <other-pc-ip>`)

## 📈 Next Steps

Once your basic setup works:

1. **Try larger models** (if you have enough VRAM):
   ```powershell
   parallax run -m Qwen/Qwen2.5-3B-Instruct -n 3
   ```

2. **Optimize for your hardware**:
   ```powershell
   parallax join --legacy-gpu --max-batch-size 6 --max-sequence-length 4096
   ```

3. **Add more nodes** for better performance:
   ```powershell
   parallax run -m Qwen/Qwen2.5-7B-Instruct -n 5
   ```

4. **Test different models** from the supported list in `LEGACY_GPU_SETUP.md`

## 🎓 Understanding What Just Happened

Your setup now:
- **Splits the LLM** across multiple GPUs (pipeline parallelism)
- **Processes requests** that flow through GPU1 → GPU2 → GPU3
- **Automatically balances** layers based on each GPU's capability
- **Uses legacy-compatible** attention mechanisms (torch_native)
- **Reduces batch sizes** automatically for stability

This proves that you can run larger models than any single GPU could handle!

## 🚀 Building Your Marketplace

For your B2B decentralized GPU marketplace vision:

1. **This demo proves** the core tech works across mixed hardware
2. **Next steps** would be:
   - Windows system tray app for easy node management
   - Auto-discovery of idle GPU time
   - Usage tracking & billing integration
   - Node reputation/reliability scoring
   - API gateway for enterprise customers

You've just validated the foundation! 🎉

---

**Questions?** Check `LEGACY_GPU_SETUP.md` for detailed troubleshooting.

**Ready for production?** Consider:
- Using RTX 3060+ for better performance
- Adding monitoring & alerting
- Implementing auto-scaling
- Setting up load balancing across multiple pipelines

