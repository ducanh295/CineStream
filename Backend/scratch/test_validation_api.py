import urllib.request
import urllib.error
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "http://localhost:5182/api"

def request(method, path, payload=None, token=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
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
    print("   KIEM TRA TDD: DATA ANNOTATIONS DTO VALIDATION (STEP 3.1)")
    print("==========================================================")

    # Dang nhap Admin de kiem tra validation tren cac endpoint duoc bao ve
    s_admin, d_admin = request("POST", "/auth/login", {
        "usernameOrEmail": "admin@cinestream.com",
        "password": "Admin@123"
    })
    admin_token = d_admin.get("data", {}).get("token") if s_admin == 200 else None

    results = []

    # 1. Register with invalid email format
    s, d = request("POST", "/auth/register", {
        "username": "validuser123",
        "email": "invalid-email-format",
        "password": "ValidPassword123"
    })
    is_400_email = (s == 400)
    results.append(("1. POST /api/auth/register (Invalid Email format)", is_400_email, s, d))

    # 2. Register with password too short (< 6 chars)
    s, d = request("POST", "/auth/register", {
        "username": "validuser456",
        "email": "valid456@gmail.com",
        "password": "123"
    })
    is_400_pass = (s == 400)
    results.append(("2. POST /api/auth/register (Password < 6 chars)", is_400_pass, s, d))

    # 3. Create Category with Name > 100 chars
    s, d = request("POST", "/categories", {
        "name": "A" * 105,
        "description": "Mo ta the loai"
    }, token=admin_token)
    is_400_cat_name = (s == 400)
    results.append(("3. POST /api/categories (Name > 100 chars)", is_400_cat_name, s, d))

    # 4. Create Movie with invalid release year (< 1888)
    s, d = request("POST", "/movies", {
        "title": "Phim Co Dai",
        "releaseYear": 1800,
        "duration": 90,
        "categoryIds": [1]
    }, token=admin_token)
    is_400_year = (s == 400)
    results.append(("4. POST /api/movies (ReleaseYear < 1888)", is_400_year, s, d))

    # 5. Create Movie with negative duration
    s, d = request("POST", "/movies", {
        "title": "Phim Thoi Luong Am",
        "releaseYear": 2024,
        "duration": -10,
        "categoryIds": [1]
    }, token=admin_token)
    is_400_duration = (s == 400)
    results.append(("5. POST /api/movies (Duration < 1 min)", is_400_duration, s, d))

    print("\nKet qua chi tiet:")
    all_passed = True
    for name, passed, status, resp in results:
        mark = "[PASS]" if passed else "[FAIL]"
        if not passed:
            all_passed = False
        print(f"{mark} {name} (HTTP Status: {status})")
        if not passed:
            print(f"       -> Phản hồi: {resp}")

    print("\nTong ket:")
    print(f"Trang thai: {'TAT CA TEST PASSED (GREEN)' if all_passed else 'CO TEST THAT BAI (DUNG TIEN TRINH TDD - RED PHASE)'}")
    return all_passed

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
