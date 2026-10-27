"""Server penerima barang bukti dari aplikasi TKP Collector.

Jalankan:  python server.py   (lalu buka http://<IP-laptop>:8000/api/health dari HP)
"""
import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path

import uvicorn
from fastapi import FastAPI, File, Form, HTTPException, UploadFile

STORAGE = Path(__file__).parent / "evidence"
app = FastAPI(title="TKP Evidence Server")


def safe_name(text: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "_", text).strip("._")[:80]


@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.post("/api/upload_evidence")
async def upload_evidence(
    file: UploadFile = File(...),
    case_id: str = Form(...),
    label: str = Form(""),
    captured_at: str = Form(""),
    latitude: float | None = Form(None),
    longitude: float | None = Form(None),
    accuracy: float | None = Form(None),
):
    case_dir_name = safe_name(case_id)
    if not case_dir_name:
        raise HTTPException(400, "case_id tidak valid")
    data = await file.read()
    if not data:
        raise HTTPException(400, "file kosong")

    received_at = datetime.now(timezone.utc)
    sha256 = hashlib.sha256(data).hexdigest()
    ext = Path(file.filename or "").suffix.lower() or ".jpg"
    base = f"{received_at:%Y%m%d_%H%M%S_%f}_{sha256[:8]}"

    case_dir = STORAGE / case_dir_name
    case_dir.mkdir(parents=True, exist_ok=True)
    (case_dir / f"{base}{ext}").write_bytes(data)
    meta = {
        "case_id": case_id,
        "label": label,
        "captured_at": captured_at,
        "received_at": received_at.isoformat(),
        "latitude": latitude,
        "longitude": longitude,
        "accuracy_m": accuracy,
        "original_filename": file.filename,
        "size_bytes": len(data),
        "sha256": sha256,
    }
    (case_dir / f"{base}.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False))
    print(f"[+] {case_id}: {base}{ext} ({len(data)} byte) lat={latitude} lng={longitude}")
    return {"saved": f"{case_dir_name}/{base}{ext}", "sha256": sha256}


if __name__ == "__main__":
    # 0.0.0.0 supaya HP di Wi-Fi yang sama bisa mengakses laptop ini
    uvicorn.run(app, host="0.0.0.0", port=8000)
