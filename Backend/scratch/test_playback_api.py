import urllib.request
import urllib.error
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "http://localhost:5182/api/movies"

def request(method, url):
    req = urllib.request.Request(url, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            status = response.status
            content = json.loads(response.read().decode("utf-8"))
            return status, content
    except urllib.error.HTTPError as e:
        status = e.code
        try:
            content = json.loads(e.read().decode("utf-8"))
        except Exception:
            content = {"raw": e.reason}
        return status, content
    except Exception as e:
        return 0, {"error": str(e)}

def run_tests():
    print("==========================================================")
    print("   KIEM TRA TDD: PLAYBACK API DUAL STREAM (HLS + CDN)")
    print("==========================================================")
    results = []

    # 1. Test GET /api/movies/1/playback (HLS Movie)
    s, d = request("GET", f"{BASE_URL}/1/playback")
    data = d.get("data", {})
    is_hls = (s == 200 and 
              d.get("success") is True and 
              data.get("streamType") == "HLS" and 
              data.get("streamUrl", "").endswith(".m3u8") and
              data.get("movieId") == 1)
    results.append(("1. GET /api/movies/1/playback (HLS)", is_hls, s, d.get("message"), f"StreamType: {data.get('streamType')} | URL: {data.get('streamUrl')}"))

    # 2. Test GET /api/movies/2/playback (CDN Direct MP4 Movie)
    s, d = request("GET", f"{BASE_URL}/2/playback")
    data = d.get("data", {})
    is_cdn = (s == 200 and 
              d.get("success") is True and 
              data.get("streamType") == "DIRECT_MP4" and 
              "media.gettr.com" in data.get("streamUrl", "") and
              data.get("movieId") == 2)
    results.append(("2. GET /api/movies/2/playback (CDN MP4)", is_cdn, s, d.get("message"), f"StreamType: {data.get('streamType')} | URL: {data.get('streamUrl')}"))

    # 3. Test GET /api/movies/999999/playback (Not Found)
    s, d = request("GET", f"{BASE_URL}/999999/playback")
    is_not_found = (s == 404 and d.get("success") is False)
    results.append(("3. GET /api/movies/999999/playback (Expect 404)", is_not_found, s, d.get("message"), None))

    # 4. Test GET /api/movies/1 (MovieDetailDto has streamType)
    s, d = request("GET", f"{BASE_URL}/1")
    data = d.get("data", {})
    has_stream_type_1 = (s == 200 and data.get("streamType") == "HLS")
    results.append(("4. GET /api/movies/1 (Detail contains streamType=HLS)", has_stream_type_1, s, d.get("message"), f"StreamType: {data.get('streamType')}"))

    # 5. Test GET /api/movies/2 (MovieDetailDto has streamType)
    s, d = request("GET", f"{BASE_URL}/2")
    data = d.get("data", {})
    has_stream_type_2 = (s == 200 and data.get("streamType") == "DIRECT_MP4")
    results.append(("5. GET /api/movies/2 (Detail contains streamType=DIRECT_MP4)", has_stream_type_2, s, d.get("message"), f"StreamType: {data.get('streamType')}"))

    print("\nKet qua kiem tra:")
    all_passed = True
    for name, passed, status, msg, extra in results:
        mark = "[PASS]" if passed else "[FAIL]"
        if not passed:
            all_passed = False
        print(f"{mark} {name} (Status: {status})")
        if extra:
            print(f"       -> {extra}")
        if not passed:
            print(f"       -> Message: {msg}")

    print("\nTong ket:")
    print(f"Trang thai: {'TAT CA DA DAT' if all_passed else 'CO TEST THAT BAI (DUNG TIEN TRINH TDD - RED PHASE)'}")
    return all_passed

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
