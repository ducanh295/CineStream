# TAI LIEU TOAN DIEN VE KIEN TRUC VA NGUYEN LY HOAT DONG CUA HLS (HTTP LIVE STREAMING)
## He thong CineStream - Tai lieu danh cho Bao ve Do an Tot nghiep

---

## MUC LUC
1. Ban chat cot loi va Mental Model (Hinh tuong hoa de nho)
2. Ban do tap tin va File chiu trach nhiem trong CineStream
3. Luong hoat dong chi tiet cua ma nguon (Code Execution Flow)
4. Kich ban chi tiet khi Nguoi dung (User) su dung
5. Bo cau hoi va Tra loi tu Co ban den Nang cao (On luyen phan bien Hoi dong)

---

## 1. BAN CHAT COT LOI VA MENTAL MODEL (HINH TUONG HOA DE NHO)

De hieu duoc HLS, hay so sanh 2 mo hinh phat video tren Internet:

### Mo hinh 1: Phat file MP4 truyen thong (Progressive Download)
- **Hinh tuong**: File MP4 giong nhu mot cuon sach day 1.000 trang dong gay lien nang 10kg.
- **Cach thuc**: Khi ban muon doc trang 500, bưu dien phai cho nguyen cuon sach 10kg ve nha ban. Trinh duyet phai tai mot phan lon file (dac biet la khoi sieu du lieu moov atom nam o dau hoac cuoi file) moi co the bat dau chieu.
- **Nhuoc diem**:
  - Khoi dong cham: Phai cho download du du lieu vao bo dem.
  - Ton bang thong may chu: Nguoi dung chi xem 2 phut roi tat, nhung trinh duyet da lo tai truoc 30 phut video, gay lang phi bang thong cuc lon.
  - Tua phim cham chap va de bi nghen mang (buffering).

### Mo hinh 2: Phat luong thich ung HLS (HTTP Live Streaming)
- **Hinh tuong**: HLS lay cuon sach 1.000 trang do, cat roi thanh 100 to roi nho (moi to 10 trang, tuong ung cac file `.ts`), sau do lap mot to "Muc luc tong hop" (file `master.m3u8`).
- **Cach thuc**:
  - Nguoi dung mo trang sach dau tien: Trinh duyet chi can keo to giay so 0 (`master0.ts`, nang ~1MB). Video lap tuc phat trong 0.2 giay!
  - Nguoi dung xem tiep: Trinh duyet am tham rut to tiep theo (`master1.ts`, `master2.ts`).
  - Nguoi dung tua den phut 60: Trinh duyet tra to Muc luc `master.m3u8`, thay phut 60 nam o to so 360 (`master360.ts`). No chi rut dung to `master360.ts` ve phat. Toan bo 359 to truoc do hoan toan khong bi tai ve!
- **Dac diem then chot**:
  - HLS thuc chat KHONG PHAI la cong nghe stream bang Socket hay kenh truyen dac biet.
  - HLS thuc chat la **Phat video bang giao thuc Web thong thuong (HTTP GET)** thong qua hang loat cac file nho.

---

## 2. BAN DO TAP TIN VA FILE CHIU TRACH NHIEM TRONG CINESTREAM

Trong du an CineStream, toan bo quy trinh HLS duoc phan chia trach nhiem ro rang giua cac thanh phan:

```text
E:\CODE\VietFlix\
│
├── Video MP4 Nguon (D:\Downloads\phim.mp4)
│   └── File chua ma hoa, do nguoi dung tai ve (codec AV1/VP9/H264)
│
├── Backend/split_video.bat (Cong cu Tien xu ly - Preprocessing)
│   └── Chay FFmpeg tren GPU NVIDIA RTX 3050 (NVENC)
│   └── Chuyen ma video sang H.264, am thanh sang AAC
│   └── Bam nho thanh 611 file .ts (moi file 10 giay) kem file master.m3u8
│
├── Backend/wwwroot/videos/1/ (Kho luu tru tai nguyen tinh)
│   ├── master.m3u8    <-- Tap tin Danh muc Playlist (Manifest)
│   ├── master0.ts      <-- Phan doan video giay 0 -> 10
│   ├── master1.ts      <-- Phan doan video giay 10 -> 20
│   └── ...
│   └── master610.ts    <-- Phan doan cuoi cung cua phim
│
├── Backend/Program.cs (Cau hinh Ha tang Web Server)
│   ├── app.UseCors("AllowAll") -> Cho phep Web/App goi API xuyen domain
│   ├── FileExtensionContentTypeProvider -> Dinh nghia MIME Type:
│   │   ├── .m3u8 -> application/vnd.apple.mpegurl
│   │   └── .ts   -> video/mp2t
│   └── app.UseStaticFiles(...) -> Cho phep trinh duyet tai file tinh tu wwwroot
│
├── Backend/Controllers/MoviesController.cs & MovieService.cs (API Quan ly)
│   ├── GET /api/movies/{id} -> Tra ve VideoUrl: "http://localhost:5182/videos/1/master.m3u8"
│   └── PUT /api/movies/{id} -> Cap nhat VideoUrl va thoi luong phim
│
└── Backend/wwwroot/player.html (Trinh phat Client kiem thu)
    ├── Thu vien Hls.js -> Trinh thong dich va giai ma HLS cho trinh duyet
    └── The <video> -> Hien thi hinh anh va phat am thanh ra loa
```

---

## 3. LUONG HOAT DONG CHI TIET CUA MA NGUON (CODE EXECUTION FLOW)

Quy trinh tu luc bam nut "Xem Phim" den khi hinh anh xuat hien tren man hinh dien ra theo 5 giai doan tuan tu:

### Giai doan 1: Lay duong dan luong phat (Metadata Handshake)
1. Ung dung Client (Flutter Mobile hoac Web Player) gui HTTP Request:
   `GET http://localhost:5182/api/movies/1`
2. `MoviesController.cs` tiep nhan yeu cau, goi `MovieService.GetByIdAsync(1)`.
3. Database PostgreSQL tra ve thong tin phim:
   ```json
   {
     "id": 1,
     "title": "Quan Xam Loc Coc (Chau Tinh Tri)",
     "duration": 106,
     "videoUrl": "http://localhost:5182/videos/1/master.m3u8"
   }
   ```
4. Client nhan duoc `videoUrl` va chuyen giao URL nay cho trinh phat video.

### Giai doan 2: Phan tich ban do luong phat (Manifest Parsing)
1. Trinh phat (Hls.js hoac VideoPlayer tren Mobile) gui request:
   `GET http://localhost:5182/videos/1/master.m3u8`
2. Backend ASP.NET Core (`Program.cs`) doc file `master.m3u8` tu dia cung va tra ve voi Header:
   `Content-Type: application/vnd.apple.mpegurl`
3. Client phan tich noi dung file `master.m3u8`:
   - Tim thay the `#EXT-X-TARGETDURATION:10`: Do dai toi da cua moi doan la 10 giay.
   - Tim thay danh sach cac file tu `master0.ts` den `master610.ts`.
   - Tim thay the **`#EXT-X-ENDLIST`** o cuoi file -> Client xac nhan day la **Phim xem theo yeu cau (VOD)**, khong phai Livestream.
   - Client tinh tong thoi luong bang tong cac the `#EXTINF` va hien thi thanh timeline: `01:45:58`.

### Giai doan 3: Nap bo dem va Khoi tao hinh anh (Initial Buffering)
1. Client tu dong yeu cau phan doan dau tien:
   `GET http://localhost:5182/videos/1/master0.ts`
2. Backend tra ve file nhi phan voi Header:
   `Content-Type: video/mp2t`
3. Trinh phat nhet du lieu nhi phan nay vao `SourceBuffer` trong RAM cua thiet bi.
4. Trinh phat giai ma luong H.264 (khung hinh) va luong AAC (am thanh), day vao bo phat cua the `<video>`.
5. Video bat dau phat ngay tai giay `00:00:00`.

### Giai doan 4: Tai cuon chieu lien tuc (Sliding Window Buffering)
1. Trong khi nguoi dung dang xem `master0.ts` (giay thu 0 den 10), trinh phat khong ngoi cho.
2. Trinh phat lap tuc gui tiep yeu cau tai `master1.ts` va `master2.ts` de luon giu mot khoang du phong trong RAM (Buffer Ahead) khoang 20-30 giay.
3. Khi nguoi xem xem het `master0.ts`, trinh phat tu dong noi tiep `master1.ts` ma khong bi chop hay ngat quang mot mili-giay nao (Seamless Playback).

### Giai doan 5: Xu ly khi nguoi dung tua phim (Seeking / Scrubbing)
1. Nguoi dung keo thanh tua den phut `01:00:00` (giay thu 3600).
2. Trinh phat lap tuc huy bo (Abort) cac request dang tai dở o phut dau.
3. Trinh phat tinh toan:
   `Chi so phan doan = 3600 giay / 10.4 giay moi doan ≈ 346`
4. Trinh phat gui request:
   `GET http://localhost:5182/videos/1/master346.ts`
5. Ngay khi file `master346.ts` tai ve xong, khung hinh tai phut thu 60 lap tuc hien thi va phat tiep.

---

## 4. KICH BAN CHI TIET KHI NGUOI DUNG (USER) SU DUNG

### Kich ban 1: Nguoi dung mo phim xem lan dau (Cold Start)
- **Hanh dong**: Nguoi dung nhan vao phim "Quan Xam Loc Coc".
- **Phia sau he thong**:
  - App lay manifest `master.m3u8`.
  - App chi can tai dung file `master0.ts` (dung luong ~1.5 MB).
- **Ket qua**: Video khoi dong ngay lap tuc sau 0.3 giay, khong phai cho doi du phim dai gan 2 tieng.

### Kich ban 2: Nguoi dung dang xem thi mang bi chap chon / yeu dot ngot
- **Hanh dong**: Nguoi dung di vao thang may hoac vung song 4G yeu.
- **Phia sau he thong**:
  - Do trinh phat luon tai truoc 20-30 giay vao RAM (Buffer), video van phat tiep binh thuong trong khi mang dang yeu.
  - Neu mang mat hoan toan qua 30 giay, trinh phat hien thi vong xoay tai (Loading Spinner) va kien nhan retry request lai file `.ts` hien tai. Khi co mang tro lai, video lap tuc phat tiep ma khong bi khoi dong lai tu dau.

### Kich ban 3: Nguoi dung xem do roi thoat ra, hom sau xem tiep (Resume Playback)
- **Hanh dong**: Xem den phut `45:30` thi dong ung dung. Hom sau mo lai.
- **Phia sau he thong**:
  - App doc tu Database vi tri xem cu: `playbackPosition = 2730` (giay).
  - Trinh phat nhay thang den phan doan: `2730 / 10.4 ≈ master262.ts`.
- **Ket qua**: Phim tiep tuc phat dung giay thu `45:30`, nguoi dung khong can xem lai tu dau va khong ton bat ky byte du lieu nao cua 45 phut truoc.

---

## 5. BO CAU HOI VA TRA LOI TU CO BAN DEN NANG CAO (ON PHAN BIEN HOI DONG)

### [CO BAN] Cau 1: HLS la gi? Tai sao ten goi la "Live Streaming" ma chung ta lai dung de chieu phim theo yeu cau (VOD)?
- **Tra loi**: HLS (HTTP Live Streaming) la giao thuc do Apple phat minh ban dau voi muc tieu phat truc tiep (Livestream) cac su kien qua trinh duyet Safari tren iPhone. Tuy nhien, do kien truc chia nho video thanh cac file `.ts` va dieu phoi bang file `.m3u8` qua mang HTTP qua hieu qua va de trien khai, no da tro thanh chuan cong nghiep toan cau ap dung cho ca:
  1. **Livestream**: File `master.m3u8` duoc cap nhat lien tuc, khong co the `#EXT-X-ENDLIST`.
  2. **VOD (Video On Demand - Phim xem theo yeu cau)**: File `master.m3u8` co dinh toan bo danh sach va ket thuc bang the `#EXT-X-ENDLIST`.

### [CO BAN] Cau 2: File master.m3u8 va file master0.ts khac nhau the nao? Mo bang Notepad xem duoc khong?
- **Tra loi**:
  - `master.m3u8`: La file **van ban thuan (Plain Text, ma hoa UTF-8)**. Ban hoan toan mo duoc bang Notepad. No khong chua bat ky hinh anh hay am thanh nao, ma chi la danh sach cac dong lenh huong dan trinh phat biet can phai tai file nao va thoi luong bao nhieu.
  - `master0.ts`: La file **nhi phan da phuong tien (Binary MPEG-2 Transport Stream)**. Mo bang Notepad se chi thay cac ky tu vo nghia. File nay chua du lieu khung hinh video (H.264) va am thanh (AAC) duoc dong goi theo tieu chuan truyen hinh so.

### [CO BAN] Cau 3: The #EXT-X-ENDLIST co y nghia gi? Neu thieu the nay thi chuyen gi se xay ra?
- **Tra loi**:
  - Day la the bao hieu ket thuc danh sach phat (End of List).
  - **Neu CO the `#EXT-X-ENDLIST`**: Trinh phat xac dinh day la phim VOD hoan chinh, bat dau phat tu giay 0 (`master0.ts`) va cho phep nguoi dung tua phim tu do tren toan bo thoi luong.
  - **Neu THIEU the `#EXT-X-ENDLIST`**: Trinh phat quy uoc day la buoi phat song truc tiep (Livestream) dang tiep dien. Theo chuan RFC 8216, khi xem livestream, trinh phat bat buoc phai nhay ngay den phan doan moi nhat o cuoi danh sach (Live Edge) de nguoi xem theo kip thoi gian thuc. Day chinh la ly do vi sao khi FFmpeg dang chay do ma mo web len xem thi phim lai nhay thang vao phan doan cuoi cung thay vi phat tu dau!

### [TRUNG CAP] Cau 4: Tai sao truoc do video tai tu YouTube ve bam ra lai bi "chi co tieng ma man hinh den xi"?
- **Tra loi**:
  - Video tai tu YouTube hien nay thuong duoc Google ma hoa bang codec the he moi la **AV1** hoac **VP9** nham tiet kiem bang thong cua ho.
  - Dinh dang container `.ts` (MPEG-2 Transport Stream) cua chuan HLS truyen thong **hoan toan khong ho tro video AV1**. No chi ho tro H.264 (AVC) va H.265 (HEVC).
  - Khi ta dung lenh sao chep nguyen goc (`-codec: copy`), FFmpeg khong the dong goi luong AV1 vao file `.ts`, no danh dau luong hinh anh thanh du lieu nhi phan tho (`bin_data`) va bo roi cac khung hinh, chi co luong am thanh AAC la duoc copy nguyen ven.
  - Ket qua: File `.ts` sinh ra chi co tieng ma khong he co hinh anh H.264. De khac phuc, ta bat buoc phai **chuyen ma (transcode)** video sang chuan **H.264** (`-c:v h264_nvenc` hoac `-c:v libx264`).

### [TRUNG CAP] Cau 5: Tai sao moi phan doan .ts bat buoc phai bat dau bang mot Keyframe (IDR-frame / I-frame)?
- **Tra loi**:
  - Trong nén video (H.264), co 3 loai khung hinh:
    + **I-frame (Intra-frame)**: Khung hinh doc lap hoan chinh (chua day du 100% thong tin buc anh).
    + **P-frame (Predicted)** va **B-frame (Bi-directional)**: Khung hinh phu thuoc, chi luu su thay doi so voi khung hinh truoc/sau de tiet kiem dung luong.
  - Moi file `.ts` dai 6-10 giay bat buoc phai bat dau bang mot I-frame. Neu mot file `.ts` bat dau bang P-frame hoac B-frame, trinh phat se khong the giai ma duoc hinh anh vi thieu mat khung hinh goc truoc do, dan den hien tuong man hinh bi vo hat hoac giat hinh khi chuyen doan.

### [TRUNG CAP] Cau 6: Phia Backend ASP.NET Core phai xu ly "streaming" nhu the nao? Co can socket hay cong nghe dac biet khong?
- **Tra loi**:
  - **Hoan toan khong can Socket hay Streaming Server phuc tap**.
  - Day chinh la diem thien tai cua kien truc HLS. Phia Backend thuc chat chi dong vai tro la mot **Static File Server** thong thuong.
  - Trong file `Program.cs`, ta chi can dung middleware tieu chuan:
    ```csharp
    app.UseStaticFiles(new StaticFileOptions
    {
        ContentTypeProvider = contentTypeProvider
    });
    ```
  - Khi Client yeu cau `master0.ts`, Backend chi viec doc file tu thu muc `wwwroot/videos/1/` va tra ve qua giao thuc HTTP GET tieu chuan giong nhu tra ve mot file anh JPEG hay file CSS.

### [NANG CAO] Cau 7: MIME Type la gi? Tai sao trong Program.cs bat buoc phai dang ky Mappings cho .m3u8 va .ts?
- **Tra loi**:
  - MIME Type (Multipurpose Internet Mail Extensions) la nhan dinh danh dinh dang file gui trong HTTP Response Header `Content-Type` de trinh duyet biet cach xu ly file.
  - Mac dinh, he dieu hanh Windows va ASP.NET Core khong biet file `.m3u8` va `.ts` la gi, nen se tra ve loi `404 Not Found` hoac `application/octet-stream` (tai file ve may thay vi phat).
  - Do do, ta bat buoc phai dang ky trong `Program.cs`:
    + `.m3u8` -> `application/vnd.apple.mpegurl` (Trinh duyet nhan dien day la HLS Playlist de dua vao module HLS).
    + `.ts` -> `video/mp2t` (Trinh duyet nhan dien day la Transport Stream Media de dua vao bo giai ma video).

### [NANG CAO] Cau 8: Media Source Extensions (MSE) hoat dong the nao tren trinh duyet de ghep noi cac file .ts ma khong bi khung hinh?
- **Tra loi**:
  - The HTML5 `<video>` thuan ban dau chi phat duoc file MP4 don le. No khong the tu doc tung file `.ts` roi tu ghep lai.
  - Thu vien `Hls.js` su dung API tieu chuan W3C la **Media Source Extensions (MSE)**:
    1. JavaScript tai file `.ts` ve bang `fetch()` hoac `XMLHttpRequest` duoi dang mang byte (`ArrayBuffer`).
    2. `Hls.js` chay trinh demuxer bang JavaScript / Web Worker de tach bo dem H.264 va AAC.
    3. No day cac goi tin nay vao doi tuong `SourceBuffer` gan voi the `<video>`.
    4. Trinh duyet tu dong ghep cac goi tin vao truc thoi gian (Timeline) lien tuc, giup video phat khong ti vet giua cac phan doan.

### [KHO NHAT] Cau 9: Tai sao kien truc HLS lai giup he thong CineStream chiu tai duoc hang trieu nguoi dung dong thoi (High Scalability)?
- **Tra loi**:
  - Neu dung streaming truyen thong (WebRTC, RTSP, Socket), moi nguoi xem la mot ket noi duy tri lien tuc (Stateful Connection). May chu Backend se nhanh chong tran bo nho va chay CPU khi co vai nghin nguoi xem.
  - Voi HLS, moi phan doan la mot **HTTP GET Request doc lap va tinh (Stateless)**:
    1. **Kha nang luu dem tai Edge (CDN Caching)**: File `master0.ts` mot khi da sinh ra thi khong bao gio thay doi. Khi trien khai thuc te, ta dat Cloudflare / CloudFront dung truoc Backend.
    2. Khi 100.000 nguoi xem cung luc, chi co nguoi dau tien yeu cau file tu Backend CineStream. May chu CDN se luu dem (Cache) file do lai. 99.999 nguoi tiep theo se nhan file truc tiep tu may chu CDN gan nhat.
    3. May chu Backend CineStream chiu tai = 0 cho phan video, chi con xu ly cac API nhe nhu thong tin phim va tai khoan!

### [KHO NHAT] Cau 10: Adaptive Bitrate Streaming (ABR) trong HLS la gi? Huong phat trien tuong lai cua CineStream de tu dong doi chat luong (1080p, 720p, 480p) theo toc do mang?
- **Tra loi**:
  - ABR (Phap luong thich ung theo bang thong) la dinh cao cua HLS.
  - **Mo hinh Master Playlist da tang (Multi-variant Playlist)**:
    Thay vi chi co 1 file `master.m3u8`, he thong se băm phim ra 3 thu muc tuong ung 3 do phan giai:
    + `1080p/index.m3u8` (Bitrate 3000k)
    + `720p/index.m3u8` (Bitrate 1500k)
    + `480p/index.m3u8` (Bitrate 800k)
    Va 1 file `master.m3u8` goc se liet ke ca 3 luong nay kem theo thong so `#EXT-X-STREAM-INF:BANDWIDTH=...`.
  - Khi nguoi dung dang xem, trinh phat do toc do tai cua tung doan `.ts`. Neu mang cham dot ngot, trinh phat se tu dong chuyen sang tai tiep doan ke tiep tu thu muc `480p` ma khong bi dung hinh. Khi mang khoe tro lai, no tu dong nang len `1080p`. Day la huong nang cap ma nhom sinh vien dinh huong phat trien trong giai doan 2 cua san pham.
