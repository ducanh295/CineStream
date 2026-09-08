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
    print("   KIEM TRA TDD: AUTHORIZATION POLICY ADMINONLY (STEP 3.2)")
    print("==========================================================")

    # 1. Dang nhap lay token Admin
    s_admin, d_admin = request("POST", "/auth/login", {
        "usernameOrEmail": "admin@cinestream.com",
        "password": "Admin@123"
    })
    admin_token = d_admin.get("data", {}).get("token") if s_admin == 200 else None
    print(f"Dang nhap Admin: HTTP {s_admin} | Token: {'CO' if admin_token else 'KHONG'}")

    # 2. Dang nhap lay token User thuong
    s_user, d_user = request("POST", "/auth/login", {
        "usernameOrEmail": "user@cinestream.com",
        "password": "User@123"
    })
    user_token = d_user.get("data", {}).get("token") if s_user == 200 else None
    print(f"Dang nhap User:  HTTP {s_user} | Token: {'CO' if user_token else 'KHONG'}")

    results = []

    # Test 1: Goi endpoint AdminOnly khong truyen Token -> Expect 401 Unauthorized
    s, d = request("GET", "/auth/admin-check")
    is_401 = (s == 401)
    results.append(("1. GET /api/auth/admin-check (Khong Token) -> Expect 401", is_401, s, d))

    # Test 2: Goi endpoint AdminOnly bang Token User thuong -> Expect 403 Forbidden
    s, d = request("GET", "/auth/admin-check", token=user_token)
    is_403 = (s == 403)
    results.append(("2. GET /api/auth/admin-check (Token User) -> Expect 403", is_403, s, d))

    # Test 3: Goi endpoint AdminOnly bang Token Admin -> Expect 200 OK
    s, d = request("GET", "/auth/admin-check", token=admin_token)
    is_200 = (s == 200)
    results.append(("3. GET /api/auth/admin-check (Token Admin) -> Expect 200", is_200, s, d))

    print("\nKet qua chi tiet:")
    all_passed = True
    for name, passed, status, resp in results:
        mark = "[PASS]" if passed else "[FAIL]"
        if not passed:
            all_passed = False
        print(f"{mark} {name} (HTTP Status: {status})")
        if not passed:
            print(f"       -> Phan hoi: {resp}")

    print("\nTong ket:")
    print(f"Trang thai: {'TAT CA TEST PASSED (GREEN)' if all_passed else 'CO TEST THAT BAI (RED PHASE)'}")
    return all_passed

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
