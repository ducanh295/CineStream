# HLS Video Streaming Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thiet lap quy trinh băm va phat luong video HLS (HTTP Live Streaming) hoan chinh cho CineStream, giup sinh vien tu tay chuyen doi phim MP4 sang cac phan doan HLS (.m3u8 va .ts), sap xep file vao dung cau truc Backend, cap nhat Database va kiem thu xem phim truc tiep tren trinh phat HLS.

**Architecture:** Backend ASP.NET Core dong vai tro la Static HLS Streaming Server, phuc vu cac tep `.m3u8` va `.ts` tu thu muc `Backend/wwwroot/videos/{movieId}/` voi MIME Types chuan (`application/vnd.apple.mpegurl` va `video/mp2t`) va CORS `AllowAll`. Trinh phat video (Flutter App / Web) chi can nap URL `master.m3u8` de tu dong tai cac goi `.ts` theo thoi gian thuc.

**Tech Stack:** ASP.NET Core 9/10, FFmpeg 7.1, HLS Protocol (RFC 8216), HLS.js / Video.js, PostgreSQL (EF Core).

**Spec:** `docs/features-list.md`

---

## Global Constraints
- Khong commit bat ky file video `.mp4`, `.ts`, `.m3u8` nao vao Git (da co trong `.gitignore`).
- Khong dung tool tu dong phuc tap trong code Backend; giu quy trinh băm va sao chep thu cong de sinh vien nam vung 100% ban chat.
- MIME type bat buoc: `.m3u8` -> `application/vnd.apple.mpegurl`, `.ts` -> `video/mp2t`.
- Toan bo ma nguon va ghi chu tuan thu tieu chuan bao ve do an: tieng Viet chuan muc, khong icon/emoji.

---

### Task 1: Kiem Tra & Hoan Thien Ha Tang Backend Phuc Vu HLS

**Files:**
- Modify: `Backend/Program.cs`
- Verify: `Backend/wwwroot/videos/`

**Interfaces:**
- Input: HTTP GET `http://localhost:5182/videos/{movieId}/master.m3u8`
- Output: HTTP 200 voi Header `Content-Type: application/vnd.apple.mpegurl` va `Access-Control-Allow-Origin: *`

- [ ] **Step 1: Xac nhan cau hinh StaticFiles va CORS trong Program.cs**
Kiem tra thu tu middleware: `UseCors("AllowAll")` phai dung truoc `UseStaticFiles(...)`.

- [ ] **Step 2: Kiem tra su ton tai cua thu muc goc wwwroot/videos**
Dam bao thu muc `Backend/wwwroot/videos` da san sang tiep nhan cac thu muc con `{movieId}`.

- [ ] **Step 3: Test tu dong goi lenh curl/python xac thuc HTTP Headers**
Gui request den mot file test mau va kiem tra ma trang thai 200 kem Content-Type chuan.

---

### Task 2: Quy Trinh Chuan (SOP) Băm Phim MP4 Sang HLS Bang FFmpeg

**Files:**
- Create: `Backend/docs/hls-conversion-guide.md` (Cam nang huong dan chi tiet danh cho sinh vien)

**Interfaces:**
- Input: File `ten_phim.mp4` bat ky (720p hoac 1080p)
- Output: Thu muc chua `master.m3u8` va cac chunk `master0.ts`, `master1.ts`, `master2.ts`...

- [ ] **Step 1: Soan thao tai lieu huong dan băm phim**
Giai thich tung tham so dong lenh FFmpeg de sinh vien doc hieu va tu tin tra loi van dap hoi dong:
```bash
ffmpeg -i "input.mp4" -codec: copy -start_number 0 -hls_time 6 -hls_list_size 0 -f hls "master.m3u8"
```
- `-codec: copy`: Khong render lai video, giu nguyen 100% chat luong goc, toc do bam cuc nhanh (~15-30s).
- `-hls_time 6`: Cat moi phan doan 6 giay.
- `-hls_list_size 0`: Luu toan bo danh sach phat vao file `.m3u8` (VOD mode).

- [ ] **Step 2: Tao file mau batch script (tien ich tuy chon) split_video.bat**
Giup sinh vien co the keo-tha nhanh file phim vao de tu dong tao ra thu muc chua `.m3u8` va `.ts` ma khong can go tay neu muon tiet kiem thoi gian.

---

### Task 3: Xay Dung Trinh Phat HLS Test Truc Quan Ngay Tren Trinh Duyet

**Files:**
- Create: `Backend/wwwroot/player.html`

**Interfaces:**
- URL: `http://localhost:5182/player.html`
- Chuc nang: Cho phep nhap URL video HLS (vi du: `http://localhost:5182/videos/1/master.m3u8`), hien thi khung phat video thuc te, cho phep bam Play, Pause, Tua, chon chat luong de kiem tra streaming truc tiep ma khong can doi app Flutter.

- [ ] **Step 1: Tao file player.html voi thu vien HLS.js va giao dien toi gian, hien dai**
File su dung HLS.js (thu vien ma nguon mo chuan cua cong nghiep web video) de giai ma `.m3u8` va `.ts` truc tiep tren Chrome/Edge.

- [ ] **Step 2: Kiem thu mo player.html tren trinh duyet**
Kiem tra xem trinh phat co nhan duoc file video mau va tua mượt mà khong bi nghen bang thong hay khong.

---

### Task 4: Quy Trinh Dong Bo Du Lieu Vao Database (Data Ingestion)

**Files:**
- Endpoint: `PUT /api/Movies/{id}` qua Scalar UI

**Interfaces:**
- Input: JSON Request Body cap nhat phim
- Fields can cap nhat:
  - `videoUrl`: `"http://localhost:5182/videos/{id}/master.m3u8"`
  - `videoStatus`: `1`

- [ ] **Step 1: Kiem tra cau truc thu muc luu tru**
Sau khi bam phim xong, copy thu muc vao `Backend/wwwroot/videos/{id}/`.
Xac nhan file index nam tai: `Backend/wwwroot/videos/{id}/master.m3u8`.

- [ ] **Step 2: Cap nhat Database bang Scalar UI**
Mo `http://localhost:5182/scalar/v1`, chon `PUT /api/Movies/{id}`, truyen URL tren va gui request.

- [ ] **Step 3: Goi GET /api/Movies/{id} doi soat**
Kiem tra xem `videoUrl` da duoc luu chuan va `videoStatus = 1` hay chua.

---

### Task 5: Kiem Thu Tich Hop Toan Dien (End-to-End Test Journey)

**Files:**
- Test with real video clip

- [ ] **Step 1: Su dung mot video MP4 that (vi du: 1-2 phut hoac full movie)**
- [ ] **Step 2: Chay lenh FFmpeg bam ra HLS**
- [ ] **Step 3: Dat vao thu muc Backend/wwwroot/videos/1/**
- [ ] **Step 4: Mo player.html tai http://localhost:5182/player.html va thu nghiem phat video**
- [ ] **Step 5: Mo F12 (Network tab) quan sat trinh duyet tai tung file .ts 6 giay theo thoi gian thuc**
Ghi nhan hinh anh/bang chung hoat dong de dua vao bao cao do an tot nghiep.
