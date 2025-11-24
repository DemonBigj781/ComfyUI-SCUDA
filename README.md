# ComfyUI-SCUDA
A full integration of **SCUDA (GPU-over-IP)** into **ComfyUI**, enabling you to run Stable Diffusion on a **remote NVIDIA GPU** as if it were attached locally.

This fork provides:

- A **drop-in SCUDA launcher (`launch_scuda.py`)**  
- A **SCUDA configuration file (`scuda_config.json`)**  
- A **build script (`build_scuda.sh`)** that builds SCUDA automatically  
- Optional **diagnostic custom node**  
- Full, clean workflow requiring no manual `LD_PRELOAD` or CUDA hacks  

ComfyUI-SCUDA lets you connect any ComfyUI installation to any remote NVIDIA GPU over a network — cleanly, predictably, and without modifying ComfyUI’s internal code.

---

## 🔧 What is SCUDA?

SCUDA (by kevmo314) is a CUDA-over-TCP shim that intercepts CUDA calls and forwards them to a remote GPU machine.

With SCUDA:

- The **GPU machine** runs a SCUDA server (`server_*.so`)  
- The **client machine** preloads a SCUDA library (`libscuda_*.so`)  
- CUDA appears “local,” but executes remotely  

ComfyUI-SCUDA wraps this into a seamless launcher that configures everything automatically.

---

# 📦 Features

### ✔ Automatic SCUDA integration
The launcher injects SCUDA environment variables and LD_PRELOAD automatically.

### ✔ Plug-and-play setup
Your entire SCUDA configuration lives in one easy JSON file.

### ✔ SCUDA build script included
`build_scuda.sh` builds the SCUDA project for you (codegen + CMake).

### ✔ Works with any ComfyUI installation
No patching of ComfyUI core files.

### ✔ Optional diagnostic node
Shows whether SCUDA is active, CUDA availability, and remote GPU identity.

---

# 🖥 System Requirements

### **GPU Server Machine**  
- NVIDIA GPU  
- NVIDIA drivers & CUDA Toolkit installed  
- Python 3, CMake, GCC  

### **Client Machine (ComfyUI)**  
- Linux or macOS (Windows via WSL2 also works)  
- Python 3  
- ComfyUI environment  
- Built SCUDA client library `libscuda_*.so`  

### Network  
- 1 Gbps minimum  
- 2.5G / 10G strongly recommended for high-res  
- Works over LAN/VLAN/VPN/WireGuard/etc.

---

# 🚀 Quick Start Guide

## 1. Build SCUDA

On either machine (GPU server or client):

```bash
git clone https://github.com/DemonBigj781/ComfyUI-SCUDA.git
cd ComfyUI-SCUDA

chmod +x build_scuda.sh
./build_scuda.sh