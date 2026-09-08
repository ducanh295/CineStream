# Cam Nang Huong Dan Chuyen Doi & Phat Luong Video HLS (CineStream)

Tai lieu nay huong dan chi tiet quy trinh chuan ky thuat de chuyen doi phim tu dinh dang MP4 truyen thong sang chuan phat luong thich ung HLS (HTTP Live Streaming) va dong bo vao he thong CineStream.

---

## 1. Tong Quan Ve Chuan HLS (HTTP Live Streaming)

HLS la giao thuc phat luong video thich ung do Apple phat trien va duoc chuan hoa thanh RFC 8216. Day la chuan cong nghiep duoc cac nen tang streaming hang dau nhu Netflix, YouTube, VieON ap dung.

### Cau truc tap tin HLS:
1. **Tap tin danh sach phat (`master.m3u8`)**:
   - Dinh dang text/plain ma hoa UTF-8.
   - Chua thong tin tieu de, thoi luong tung phan doan va thu tu cac file `.ts`.
2. **Cac tap tin phan doan video (`master0.ts`, `master1.ts`, `master2.ts`...)**:
   - Dinh dang MPEG-2 Transport Stream (video H.264, audio AAC).
   - Moi file dai dung 6 giay.
   - Khi xem phim, trinh phat (Video Player tren Flutter hoac Web) chi tai lan luot tung file `.ts` theo tien do xem thuc te, giup toi uu 90% bang thong va khoi dong phim tuc thi.

---

## 2. Huong Dan Thao Tac Bam Phim Bang FFmpeg

May tinh cua ban da duoc cai dat san cong cu `ffmpeg` phien ban 7.1.

### 2.1. Lenh chuyen doi chuan (Direct Stream Copy - Khuyen nghi)
Mo terminal (PowerShell hoac Command Prompt) tai thu muc chua file phim MP4 va chay lenh:

```bash
ffmpeg -i "ten_phim.mp4" -codec: copy -start_number 0 -hls_time 6 -hls_list_size 0 -f hls master.m3u8
```

### Giai thich chi tiet tung tham so (Dung tra loi van dap Hoi dong):
- `-i "ten_phim.mp4"`: Chi dinh file video goc dau vao.
- `-codec: copy`: Che do sao chep luong du lieu truc tiep (Direct Stream Copy). Khong ma hoa/render lai video, giu nguyen 100% chat luong goc, toc do cat file cuc nhanh (phim 2 tieng chi mat 15 - 30 giay).
- `-start_number 0`: Cac file phan doan duoc danh so bat dau tu 0 (`master0.ts`, `master1.ts`...).
- `-hls_time 6`: Thoi luong ly tuong cho moi phan doan la 6 giay (can bang giua so luong HTTP requests va do muot khi tua phim).
- `-hls_list_size 0`: Che do VOD (Video on Demand). Yeu cau ghi nhan toan bo danh sach phan doan vao file `master.m3u8`, khong xoa cac doan cu nhu che do truyen hinh truc tiep (Live Broadcast).
- `-f hls`: Dinh dang dong goi dau ra la HLS.

---

## 3. Quy Trinh Sap Xep Thu Muc Trong Backend

Sau khi bam phim xong, toan bo cac file xuat ra phai duoc dua vao thu muc tĩnh cua Backend theo ma dinh danh `id` cua bo phim trong Database:

```text
Backend/
└── wwwroot/
    └── videos/
        ├── 1/                        <-- Thu muc cho phim mang ID = 1
        │   ├── master.m3u8
        │   ├── master0.ts
        │   ├── master1.ts
        │   └── ...
        │
        ├── 2/                        <-- Thu muc cho phim mang ID = 2
        │   ├── master.m3u8
        │   ├── master0.ts
        │   └── ...
        │
        └── {movieId}/                <-- Thu muc theo ID tuong ung
            ├── master.m3u8
            ├── master0.ts
            └── ...
```

---

## 4. Quy Trinh Cap Nhat Co So Du Lieu (Data Ingestion)

Sau khi copy cac file vao thu muc `wwwroot/videos/{movieId}/`:

1. Mo giao dien quan tri Scalar UI tai: `http://localhost:5182/scalar/v1`.
2. Tim den endpoint: **`PUT /api/Movies/{id}`** (thay `{id}` bang ma phim tuong ung).
3. Dien gia tri duong dan noi bo:
   ```json
   {
     "videoUrl": "http://localhost:5182/videos/{id}/master.m3u8",
     "videoStatus": 1
   }
   ```
4. Bam **Send** de cap nhat trang thai phim thanh sang san phat (`videoStatus = 1`).

---

## 5. Kiem Thu Xem Phim Truc Tiep Tren Trinh Duyet

De xac nhan luong video HLS hoat dong hoan hao truoc khi ket noi vao Flutter:
1. Mo trinh duyet truy cap: **`http://localhost:5182/player.html`**.
2. Nhap duong dan luong video (vi du: `http://localhost:5182/videos/1/master.m3u8`).
3. Bam **Tai Phim (Load Video)** va trai nghiem:
   - Kiem tra chat luong hinh anh va am thanh.
   - Bam tua den bat ky phut nao de kiem tra toc do tai phan doan.
   - Mo F12 (tab Network) de thay trinh duyet tai tung goi `masterX.ts` dai 6 giay theo thoi gian thuc.
