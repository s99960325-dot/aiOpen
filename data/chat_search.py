#!/usr/bin/env python3
"""
对话搜索工具（本地embedding版，TF-IDF + 语义双引擎）
用法:
  1. 构建索引: python chat_search.py build
  2. 搜索:     python chat_search.py search "你的问题"
  3. 交互搜索: python chat_search.py interactive

首次build会自动下载模型（~90MB），之后离线可用。
"""

import json
import os
import sys
import glob
import sqlite3
import struct
import math
import re
import hashlib
from collections import Counter

# 配置
SESSIONS_DIR = os.path.expanduser("~/.openclaw/agents/main/sessions")
DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "chat_memory.db")
GOOGLE_API_KEY = "AIzaSyDPQTqMYyRPv7LQofPzAct0HtEzZ5hAUYk"
# Google embedding优先，本地模型兜底
USE_GOOGLE = True
MODEL_NAME = "paraphrase-multilingual-MiniLM-L12-v2"

# ---------- 全局模型 ----------

_model = None

def get_model():
    global _model
    if _model is None:
        from sentence_transformers import SentenceTransformer
        print(f"  📥 加载本地模型: {MODEL_NAME}")
        _model = SentenceTransformer(MODEL_NAME)
        print("  ✅ 模型加载完成")
    return _model

def embed_texts(texts: list[str], batch_size: int = 64) -> list:
    """批量embedding，Google优先，本地兜底"""
    if USE_GOOGLE:
        try:
            return _google_embed(texts, batch_size)
        except Exception as e:
            print(f"  ⚠️ Google失败，回退本地模型: {e}")
    
    # 本地模型兜底
    model = get_model()
    all_embs = []
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]
        embs = model.encode(batch, show_progress_bar=False, normalize_embeddings=True)
        all_embs.extend(embs.tolist())
        print(f"   本地模型 {min(100, (i+batch_size)/len(texts)*100):.0f}%", end="\r", flush=True)
    return all_embs

def embed_query(text: str) -> list:
    if USE_GOOGLE:
        try:
            return _google_embed_query(text)
        except Exception:
            pass
    model = get_model()
    return model.encode([text], normalize_embeddings=True)[0].tolist()

def _google_embed(texts: list[str], batch_size: int = 100) -> list:
    import urllib.request
    url = "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:batchEmbedContents?key=" + GOOGLE_API_KEY
    all_embs = [None] * len(texts)
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]
        payload = json.dumps({
            "requests": [{"model": "models/text-embedding-004", "content": {"parts": [{"text": t}]}} for t in batch]
        }).encode()
        req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
        import ssl
        ctx = ssl.create_default_context()
        resp = urllib.request.urlopen(req, timeout=30, context=ctx)
        result = json.loads(resp.read().decode())
        for j, item in enumerate(result.get("embeddings", [])):
            all_embs[i + j] = item["values"]
    return all_embs

def _google_embed_query(text: str) -> list:
    import urllib.request
    url = "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=" + GOOGLE_API_KEY
    payload = json.dumps({"model": "models/text-embedding-004", "content": {"parts": [{"text": text}]}}).encode()
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    import ssl
    ctx = ssl.create_default_context()
    resp = urllib.request.urlopen(req, timeout=30, context=ctx)
    result = json.loads(resp.read().decode())
    return result["embedding"]["values"]

# ---------- 中文分词 ----------

def tokenize(text: str) -> list[str]:
    tokens = []
    for w in re.findall(r'[a-zA-Z0-9_]+', text.lower()):
        tokens.append(w)
    zh_chars = re.findall(r'[\u4e00-\u9fff]', text)
    for i, c in enumerate(zh_chars):
        tokens.append(c)
        if i > 0:
            tokens.append(zh_chars[i-1] + c)
    return tokens

# ---------- TF-IDF ----------

class TfidfSearch:
    def __init__(self):
        self.doc_freq = Counter()
        self.doc_count = 0
        self.vectors = {}
    
    def add_document(self, doc_id: str, text: str):
        self.doc_count += 1
        tokens = tokenize(text)
        tf = Counter(tokens)
        max_tf = max(tf.values()) if tf else 1
        vec = {}
        for term, count in tf.items():
            self.doc_freq[term] += 1
            tf_norm = 0.5 + 0.5 * count / max_tf
            vec[term] = tf_norm
        self.vectors[doc_id] = vec
    
    def finalize(self):
        for doc_id, tf_vec in self.vectors.items():
            result = {}
            for term, tf in tf_vec.items():
                idf = math.log((self.doc_count + 1) / (self.doc_freq[term] + 1)) + 1
                result[term] = tf * idf
            self.vectors[doc_id] = result
    
    def search(self, query: str, top_k: int = 5) -> list[tuple]:
        qtokens = tokenize(query)
        qtf = Counter(qtokens)
        max_tf = max(qtf.values()) if qtf else 1
        qvec = {}
        for term, count in qtf.items():
            tf_norm = 0.5 + 0.5 * count / max_tf
            idf = math.log((self.doc_count + 1) / (self.doc_freq.get(term, 0) + 1)) + 1
            qvec[term] = tf_norm * idf
        
        scores = []
        for doc_id, dvec in self.vectors.items():
            score = self._cosine(qvec, dvec)
            if score > 0:
                scores.append((doc_id, score))
        scores.sort(key=lambda x: x[1], reverse=True)
        return scores[:top_k]
    
    def _cosine(self, a: dict, b: dict) -> float:
        dot = sum(a[k] * b[k] for k in a if k in b)
        na = math.sqrt(sum(v * v for v in a.values()))
        nb = math.sqrt(sum(v * v for v in b.values()))
        return dot / (na * nb) if na > 0 and nb > 0 else 0.0

# ---------- 解析 sessions ----------

def parse_sessions(sessions_dir: str) -> list[dict]:
    files = sorted(glob.glob(os.path.join(sessions_dir, "*.jsonl")))
    sessions = []
    
    for fpath in files:
        if ".reset." in fpath or ".deleted." in fpath:
            continue
        
        session_id = os.path.basename(fpath).replace(".jsonl", "")
        messages = []
        
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        entry = json.loads(line)
                        if entry.get("type") != "message":
                            continue
                        inner = entry.get("message", {})
                        role = inner.get("role", "")
                        if role not in ("user", "assistant"):
                            continue
                        content = inner.get("content", "")
                        if isinstance(content, str):
                            text = content
                        elif isinstance(content, list):
                            parts = []
                            for item in content:
                                if isinstance(item, dict) and item.get("type") == "text":
                                    parts.append(item.get("text", ""))
                            text = "\n".join(parts)
                        else:
                            text = ""
                        
                        if text.strip():
                            messages.append(text.strip()[:2000])
                    except json.JSONDecodeError:
                        continue
        except Exception as e:
            print(f"  ⚠️ 跳过 {session_id}: {e}")
            continue
        
        if messages:
            sessions.append({
                "session_id": session_id,
                "messages": messages,
                "file_mtime": os.path.getmtime(fpath)
            })
    
    return sessions

def chunk_messages(session: dict, chunk_size: int = 5) -> list[dict]:
    msgs = session["messages"]
    chunks = []
    for i in range(0, len(msgs), chunk_size):
        group = msgs[i:i + chunk_size]
        text = "\n".join(group)
        chunks.append({
            "session_id": session["session_id"],
            "text": text,
            "msg_start": i,
            "msg_end": min(i + chunk_size, len(msgs)) - 1
        })
    return chunks

# ---------- SQLite ----------

def init_db():
    db = sqlite3.connect(DB_PATH)
    db.execute("""
    CREATE TABLE IF NOT EXISTS chunks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        text TEXT,
        msg_start INTEGER,
        msg_end INTEGER,
        file_mtime REAL,
        text_hash TEXT UNIQUE
    )
    """)
    db.execute("""
    CREATE TABLE IF NOT EXISTS vectors (
        id INTEGER PRIMARY KEY,
        embedding BLOB
    )
    """)
    db.commit()
    return db

def pack_vector(vec) -> bytes:
    import numpy as np
    return np.array(vec, dtype=np.float32).tobytes()

def unpack_vector(data: bytes):
    import numpy as np
    return np.frombuffer(data, dtype=np.float32).tolist()

def cosine_sim(a, b) -> float:
    import numpy as np
    a = np.array(a)
    b = np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))) if np.linalg.norm(a) > 0 and np.linalg.norm(b) > 0 else 0.0

# ---------- Build ----------

def build():
    print("📖 解析对话文件...")
    sessions = parse_sessions(SESSIONS_DIR)
    print(f"   {len(sessions)} 个有效session")
    
    all_chunks = []
    for s in sessions:
        all_chunks.extend(chunk_messages(s))
    print(f"   {len(all_chunks)} 个文本块")
    
    if not all_chunks:
        print("❌ 没有对话内容")
        return
    
    db = init_db()
    
    existing_hashes = set()
    try:
        rows = db.execute("SELECT text_hash FROM chunks").fetchall()
        existing_hashes = {r[0] for r in rows}
    except Exception:
        pass
    
    new_chunks = []
    for c in all_chunks:
        h = hashlib.md5(c["text"].encode()).hexdigest()
        c["text_hash"] = h
        if h not in existing_hashes:
            new_chunks.append(c)
    
    if not new_chunks:
        print("✅ 索引已是最新")
        db.close()
        return
    
    print(f"🆕 {len(new_chunks)} 个新文本块")
    
    # 存文本
    for chunk in new_chunks:
        try:
            db.execute(
                "INSERT OR IGNORE INTO chunks (session_id, text, msg_start, msg_end, file_mtime, text_hash) VALUES (?,?,?,?,?,?)",
                (chunk["session_id"], chunk["text"], chunk["msg_start"], chunk["msg_end"], chunk.get("file_mtime", 0), chunk["text_hash"])
            )
        except Exception:
            pass
    db.commit()
    
    # 拿到新插入的id
    new_ids = []
    for chunk in new_chunks:
        row = db.execute("SELECT id FROM chunks WHERE text_hash = ?", (chunk["text_hash"],)).fetchone()
        if row:
            new_ids.append((row[0], chunk["text"]))
    
    # Embedding
    print("🧠 本地生成embedding向量...")
    model = get_model()
    texts = [t for _, t in new_ids]
    
    batch_size = 64
    for i in range(0, len(texts), batch_size):
        batch_texts = texts[i:i + batch_size]
        batch_ids = [new_ids[i + j][0] for j in range(len(batch_texts))]
        
        embeddings = model.encode(batch_texts, show_progress_bar=False, normalize_embeddings=True)
        
        for row_id, emb in zip(batch_ids, embeddings):
            db.execute("INSERT OR REPLACE INTO vectors (id, embedding) VALUES (?, ?)",
                       (row_id, pack_vector(emb)))
        
        pct = min(100, (i + batch_size) / len(texts) * 100)
        print(f"   {pct:.0f}%", end="\r", flush=True)
    
    db.commit()
    total = db.execute("SELECT COUNT(*) FROM chunks").fetchone()[0]
    vec_total = db.execute("SELECT COUNT(*) FROM vectors").fetchone()[0]
    db.close()
    print(f"\n✅ 完成！{total} 条文本，{vec_total} 条向量")

# ---------- Search ----------

def search(query: str, top_k: int = 5):
    db = init_db()
    count = db.execute("SELECT COUNT(*) FROM chunks").fetchone()[0]
    vec_count = db.execute("SELECT COUNT(*) FROM vectors").fetchone()[0]
    
    if count == 0:
        print("❌ 数据库为空，先运行 build")
        db.close()
        return
    
    print(f"🔍 搜索: {query}")
    print(f"   文本 {count} 条，向量 {vec_count} 条\n")
    
    # === 语义搜索（embedding） ===
    results = []
    
    if vec_count > 0:
        print("🧠 语义搜索...")
        model = get_model()
        qvec = model.encode([query], normalize_embeddings=True)[0]
        
        # 取有向量的记录
        rows = db.execute("""
            SELECT c.id, c.session_id, c.text, v.embedding
            FROM chunks c JOIN vectors v ON c.id = v.id
        """).fetchall()
        
        scores = []
        for cid, sid, text, emb_bytes in rows:
            emb = unpack_vector(emb_bytes)
            sim = cosine_sim(qvec, emb)
            scores.append((cid, sid, text, sim))
        
        scores.sort(key=lambda x: x[3], reverse=True)
        results = scores[:top_k]
    
    # === TF-IDF搜索（兜底/补充） ===
    print("📊 关键词搜索...")
    engine = TfidfSearch()
    all_rows = db.execute("SELECT id, session_id, text FROM chunks").fetchall()
    
    for row_id, session_id, text in all_rows:
        engine.add_document(str(row_id), text)
    engine.finalize()
    
    tfidf_results = engine.search(query, top_k)
    tfidf_ids = {int(r[0]) for r in tfidf_results}
    
    # 合并：语义结果 + TF-IDF补充
    seen = set()
    merged = []
    for cid, sid, text, score in results:
        if cid not in seen:
            merged.append((cid, sid, text, f"语义:{score:.3f}"))
            seen.add(cid)
    
    for doc_id, score in tfidf_results:
        cid = int(doc_id)
        if cid not in seen:
            row = next((r for r in all_rows if r[0] == cid), None)
            if row:
                merged.append((row[0], row[1], row[2], f"关键词:{score:.3f}"))
                seen.add(cid)
    
    merged = merged[:top_k]
    
    if not merged:
        print("❌ 没有相关结果")
        db.close()
        return
    
    for i, (cid, sid, text, score_str) in enumerate(merged):
        print(f"--- 结果 {i+1} ({score_str}) ---")
        print(f"📁 {sid}")
        display = text[:500].replace("\n", "\n   ")
        print(f"📝 {display}")
        print()
    
    db.close()

def interactive():
    print("🤖 对话搜索（输入 q 退出）")
    while True:
        try:
            query = input("\n🔍 ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if query.lower() in ("q", "quit", "exit"):
            break
        if not query:
            continue
        search(query)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    cmd = sys.argv[1].lower()
    if cmd == "build":
        build()
    elif cmd == "search":
        if len(sys.argv) < 3:
            print('用法: python chat_search.py search "你的问题"')
            sys.exit(1)
        search(sys.argv[2])
    elif cmd in ("interactive", "i"):
        interactive()
    else:
        print(f"未知命令: {cmd}")
