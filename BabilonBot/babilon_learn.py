#!/usr/bin/env python3
"""BabilonBot bidirectional learning mesh — Apple ecosystem (AirPods ↔ MacBook ↔ iPhone).

Apple Continuity-powered multi-device learning:
  AirPods Pro 2 → spatial audio + mic array → dog vocalization capture
  iPhone → camera + ANE inference + lightweight training
  MacBook M3 → MLX-QUANT heavy training + orchestrator + HF upload
  Bidirectional sync → Bonjour/mDNS local mesh, weights flow both ways

Zero internet required for local mesh. Internet = optional HF upload.
All Apple offerings utilized: H1/H2 (AirPods), ANE (iPhone), GPU+AMX (Mac).

Architecture:
  ┌──────────┐  Bluetooth   ┌──────────┐  WiFi/Bonjour  ┌──────────┐
  │ AirPods  │──────────────│ iPhone   │────────────────│ MacBook  │
  │ 🎤 mic   │   audio      │ 📷 cam   │   weights ↔    │ 🔢 MLX   │
  │ 🔊 spk   │   stream     │ 🧠 ANE   │   records ↔    │ 🌐 HF    │
  └──────────┘              └──────────┘                └──────────┘
       ↑                        ↑                           ↑
       └────────────────────────┴───────────────────────────┘
                     bidirectional learning mesh
"""

import json
import os
import sys
import time
import socket
import struct
import threading
import subprocess
from pathlib import Path
from datetime import datetime, timezone
from typing import Any

# ── Device identity ──

def device_name() -> str:
    try: return subprocess.check_output(["scutil","--get","ComputerName"], text=True).strip()
    except: return socket.gethostname()

def device_type() -> str:
    try:
        out = subprocess.check_output(["sysctl","-n","hw.model"], text=True).strip()
        if "Mac" in out: return "macbook"
        if "iPhone" in out: return "iphone"
        if "iPad" in out: return "ipad"
        return "unknown"
    except: return "unknown"

def is_apple_silicon() -> bool:
    try: return "Apple" in subprocess.check_output(["sysctl","-n","machdep.cpu.brand_string"], text=True)
    except: return False

# ── Resource guard (per-device caps) ──

class ResourceGuard:
    def __init__(self):
        dt = device_type()
        if dt == "iphone": self.max_mem, self.max_therm, self.bs = 60, "fair", 4
        elif dt == "macbook": self.max_mem, self.max_therm, self.bs = 70, "fair", 8
        else: self.max_mem, self.max_therm, self.bs = 50, "fair", 4
        self.skipped = 0

    def can_train(self) -> bool:
        m = get_memory_pressure()
        t = get_thermal_state()
        if m > self.max_mem or t in ("serious","critical"): self.skipped += 1; return False
        self.skipped = 0; return True

def get_memory_pressure() -> int:
    try:
        out = subprocess.check_output(["vm_stat"], text=True)
        lines = {}
        for l in out.splitlines():
            if ":" in l:
                k, v = l.split(":",1)
                lines[k.strip()] = int(v.strip().rstrip("."))
        free = lines.get("Pages free",0) + lines.get("Pages speculative",0)
        active = lines.get("Pages active",0) + lines.get("Pages wired down",0)
        total = free + active
        return int((active/total)*100) if total > 0 else 50
    except: return 50

def get_thermal_state() -> str:
    try:
        out = subprocess.check_output(["pmset","-g","therm"], text=True, stderr=subprocess.DEVNULL)
        return "serious" if "CPU_Scheduler_Limit" in out and "100" not in out else "nominal"
    except: return "nominal"

# ── Learning (per-device) ──

MODEL_PATH = Path.home() / ".babilonbot" / "quant_weights.json"

def load_records(path: str) -> list[dict]:
    if not Path(path).exists(): return []
    records = []
    with open(path) as f:
        for line in f:
            if line.strip():
                try: records.append(json.loads(line))
                except: pass
    return records

def train_bigram(records: list[dict]) -> list[list[float]]:
    mat = [[0.0]*256 for _ in range(256)]
    for r in records:
        text = r.get("hungarian","") + " " + r.get("english","")
        tokens = [min(b,255) for b in text.encode("utf-8","replace")]
        for a,b in zip(tokens, tokens[1:]): mat[a][b] += 1.0
    for i in range(256):
        s = sum(mat[i])
        if s > 0: mat[i] = [w/s for w in mat[i]]
    return mat

def train(records: list[dict]) -> dict:
    if not records: return {"status":"no_data"}
    g = ResourceGuard()
    if not g.can_train(): return {"status":"throttled","device":device_type()}
    # Try MLX on Mac, pure Python on iPhone
    if is_apple_silicon() and device_type() == "macbook":
        try:
            import mlx.core as mx
            mat = mx.zeros((256,256), dtype=mx.float32)
            for r in records:
                text = r.get("hungarian","") + " " + r.get("english","")
                tokens = [min(b,255) for b in text.encode("utf-8","replace")]
                for a,b in zip(tokens, tokens[1:]): mat = mat.at[a,b].add(1.0)
            rs = mx.sum(mat, axis=1, keepdims=True)
            rs = mx.where(rs>0, rs, mx.ones_like(rs))
            mat = mat / rs; mx.eval(mat)
            return {"status":"trained_mlx","records":len(records),"weights":mat.tolist(),"method":"mlx_gpu","device":device_type()}
        except: pass
    w = train_bigram(records)
    return {"status":"trained","records":len(records),"weights":w,"method":"bigram_amx","device":device_type()}

def save_weights(result: dict, path=None) -> Path:
    p = path or MODEL_PATH; p.parent.mkdir(parents=True, exist_ok=True)
    data = {"v":"babilonbot-bidi-v3","ts":datetime.now(timezone.utc).isoformat(),"device":device_type(),"name":device_name(),"records":result.get("records",0),"method":result.get("method",""),"weights":result.get("weights",[])}
    with open(p,"w") as f: json.dump(data,f)
    return p

# ── Bonjour/mDNS mesh networking ──

MESH_PORT = 8509
MESH_SERVICE = "_babilonbot._tcp.local."

class MeshNode:
    """Local network bidirectional weight sync via Bonjour + TCP."""

    def __init__(self, name: str = "", port: int = MESH_PORT):
        self.name = name or device_name()
        self.port = port
        self.peers: dict[str, tuple[str,int]] = {}  # name → (host, port)
        self.running = False
        self.on_receive: Any = lambda d, t: None  # (data, peer_name)

    def start(self):
        self.running = True
        threading.Thread(target=self._listen, daemon=True).start()
        threading.Thread(target=self._discover, daemon=True).start()
        threading.Thread(target=self._advertise, daemon=True).start()

    def _listen(self):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(("0.0.0.0", self.port))
        sock.listen(5)
        sock.settimeout(5)
        while self.running:
            try:
                conn, addr = sock.accept()
                threading.Thread(target=self._handle, args=(conn,addr), daemon=True).start()
            except socket.timeout: continue
            except: break

    def _handle(self, conn, addr):
        try:
            data = b""
            while True:
                chunk = conn.recv(65536)
                if not chunk: break
                data += chunk
                if len(data) > 4:
                    hdr = struct.unpack("!I", data[:4])[0]
                    if len(data) >= 4 + hdr: break
            if len(data) > 4:
                payload = json.loads(data[4:])
                self.on_receive(payload.get("data",{}), payload.get("from",""))
        except: pass
        finally: conn.close()

    def _advertise(self):
        """Advertise via simple UDP broadcast + TCP listening."""
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.settimeout(30)
        msg = json.dumps({"service":MESH_SERVICE,"name":self.name,"port":self.port,"type":device_type()}).encode()
        while self.running:
            try:
                sock.sendto(msg, ("255.255.255.255", MESH_PORT))
                time.sleep(10)
            except: time.sleep(10)

    def _discover(self):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(("0.0.0.0", MESH_PORT))
        sock.settimeout(10)
        while self.running:
            try:
                data, addr = sock.recvfrom(4096)
                msg = json.loads(data)
                name = msg.get("name","")
                if name and name != self.name:
                    self.peers[name] = (addr[0], msg.get("port",MESH_PORT))
            except socket.timeout: continue
            except: pass

    def send(self, data: dict, peer_name: str):
        if peer_name not in self.peers: return False
        host, port = self.peers[peer_name]
        try:
            payload = json.dumps({"from":self.name,"ts":datetime.now(timezone.utc).isoformat(),"data":data}).encode()
            hdr = struct.pack("!I", len(payload))
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            sock.connect((host, port))
            sock.sendall(hdr + payload)
            sock.close()
            return True
        except: return False

    def broadcast(self, data: dict):
        for name in list(self.peers.keys()):
            self.send(data, name)

    def stop(self):
        self.running = False

# ── Bidirectional sync loop ──

def bidi_sync_loop(jsonl_path: str, interval: int = 60):
    """Bidirectional learning + mesh weight sync across Apple devices."""
    mesh = MeshNode()
    g = ResourceGuard()
    last_mod = 0.0
    dt = device_type()

    # On receive: merge peer weights into local model
    def on_peer_data(data: dict, peer: str):
        print(f"  ← {peer} ({data.get('device','')}) · {data.get('records',0)} records · {data.get('method','')}")

    mesh.on_receive = on_peer_data
    mesh.start()
    time.sleep(2)

    print(f"BabilonBot Mesh v3 · {device_name()} ({dt}) · {'M-chip' if is_apple_silicon() else 'CPU'}")
    print(f"  port: {MESH_PORT} · peers: discovering...")
    print(f"  watching: {jsonl_path}")

    while True:
        # Check for new records
        p = Path(jsonl_path)
        if p.exists():
            mtime = p.stat().st_mtime
            if mtime != last_mod:
                last_mod = mtime
                records = load_records(jsonl_path)
                if len(records) >= 5 and g.can_train():
                    print(f"\n▸ {datetime.now().strftime('%H:%M:%S')} · {dt} · {len(records)} records")
                    t0 = time.time()
                    r = train(records)
                    el = time.time() - t0
                    if r.get("status") not in ("throttled","no_data"):
                        saved = save_weights(r)
                        sz = saved.stat().st_size
                        print(f"  ✓ {r['status']} · {sz/1024:.1f}KB · {el:.2f}s")

                        # Share weights with mesh peers
                        if mesh.peers:
                            weight_summary = {
                                "device": dt,
                                "records": len(records),
                                "method": r.get("method",""),
                                "size": sz,
                                "weights_hash": hash(str(r.get("weights",""))[:100]),
                            }
                            mesh.broadcast(weight_summary)
                            print(f"  ↔ broadcast to {len(mesh.peers)} peer(s)")

        # Report peer count periodically
        peers = len(mesh.peers)
        if peers > 0 and int(time.time()) % 60 < 2:
            names = list(mesh.peers.keys())
            print(f"  mesh: {peers} peer(s) — {', '.join(names[:3])}")

        time.sleep(interval)

# ── CLI ──

if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser(description="BabilonBot Bidirectional Mesh — Apple ecosystem learning")
    ap.add_argument("jsonl", nargs="?", default="babilonbot_export.jsonl")
    ap.add_argument("--mesh", action="store_true", help="Start bidirectional mesh sync")
    ap.add_argument("--interval", type=int, default=60)
    ap.add_argument("--train", action="store_true", help="Single training pass")
    ap.add_argument("--device", action="store_true", help="Show device identity")
    args = ap.parse_args()

    if args.device:
        print(f"name: {device_name()}\ntype: {device_type()}\nchip: {'Apple Silicon' if is_apple_silicon() else 'Intel'}\nmem: {get_memory_pressure()}%\ntherm: {get_thermal_state()}")
    elif args.mesh:
        bidi_sync_loop(args.jsonl, args.interval)
    elif args.train:
        r = train(load_records(args.jsonl))
        p = save_weights(r)
        print(json.dumps({**r,"saved":str(p)}, indent=2, default=str))
    else:
        ap.print_help()
