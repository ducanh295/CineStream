import urllib.request
import urllib.error
import json
import sys
import time

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
    print("   KIEM TRA TDD: PHAN QUYEN CONTROLLERS (STEP 3.3)")
    print("==========================================================")

    # 1. Dang nhap Admin
    s_admin, d_admin = request("POST", "/auth/login", {
        "usernameOrEmail": "admin@cinestream.com",
        "password": "Admin@123"
    })
    admin_token = d_admin.get("data", {}).get("token") if s_admin == 200 else None
    print(f"Dang nhap Admin: HTTP {s_admin} | Token: {'CO' if admin_token else 'KHONG'}")

    # 2. Dang nhap User thuong
    s_user, d_user = request("POST", "/auth/login", {
        "usernameOrEmail": "user@cinestream.com",
        "password": "User@123"
    })
    user_token = d_user.get("data", {}).get("token") if s_user == 200 else None
    print(f"Dang nhap User:  HTTP {s_user} | Token: {'CO' if user_token else 'KHONG'}")

    timestamp = int(time.time())
    results = []

    # --- NHOM 1: PUBLIC ENDPOINTS (GET phai luon truy cap duoc khong can token) ---
    s, d = request("GET", "/categories")
    results.append(("1. GET /api/categories (Public khong token) -> Expect 200", s == 200, s, d))

    s, d = request("GET", "/movies")
    results.append(("2. GET /api/movies (Public khong token) -> Expect 200", s == 200, s, d))

    s, d = request("GET", "/movies/1/playback")
    results.append(("3. GET /api/movies/1/playback (Public khong token) -> Expect 200", s == 200, s, d))

    # --- NHOM 2: CATEGORIES ADMIN PROTECTION (POST, PUT, DELETE) ---
    cat_payload = {"name": f"AuthCat_{timestamp}", "description": "Test phan quyen"}
    
    # POST categories
    s, d = request("POST", "/categories", cat_payload)
    results.append(("4. POST /api/categories (Khong token) -> Expect 401", s == 401, s, d))

    s, d = request("POST", "/categories", cat_payload, token=user_token)
    results.append(("5. POST /api/categories (Token User) -> Expect 403", s == 403, s, d))

    s, d = request("POST", "/categories", cat_payload, token=admin_token)
    created_cat_id = d.get("data", {}).get("id") if s == 201 else None
    results.append(("6. POST /api/categories (Token Admin) -> Expect 201", s == 201, s, d))

    # PUT categories
    put_cat_id = created_cat_id if created_cat_id else 1
    s, d = request("PUT", f"/categories/{put_cat_id}", {"name": f"AuthCat_Up_{timestamp}", "description": "Sua"})
    results.append(("7. PUT /api/categories (Khong token) -> Expect 401", s == 401, s, d))

    s, d = request("PUT", f"/categories/{put_cat_id}", {"name": f"AuthCat_Up_{timestamp}", "description": "Sua"}, token=user_token)
    results.append(("8. PUT /api/categories (Token User) -> Expect 403", s == 403, s, d))

    # DELETE categories
    del_cat_id = created_cat_id if created_cat_id else 999999
    s, d = request("DELETE", f"/categories/{del_cat_id}")
    results.append(("9. DELETE /api/categories (Khong token) -> Expect 401", s == 401, s, d))

    s, d = request("DELETE", f"/categories/{del_cat_id}", token=user_token)
    results.append(("10. DELETE /api/categories (Token User) -> Expect 403", s == 403, s, d))

    if created_cat_id:
        s, d = request("DELETE", f"/categories/{created_cat_id}", token=admin_token)
        results.append(("11. DELETE /api/categories (Token Admin) -> Expect 200", s == 200, s, d))

    # --- NHOM 3: MOVIES ADMIN PROTECTION (POST, PUT, DELETE) ---
    movie_payload = {
        "title": f"AuthMovie_{timestamp}",
        "releaseYear": 2024,
        "duration": 120,
        "categoryIds": [1]
    }

    # POST movies
    s, d = request("POST", "/movies", movie_payload)
    results.append(("12. POST /api/movies (Khong token) -> Expect 401", s == 401, s, d))

    s, d = request("POST", "/movies", movie_payload, token=user_token)
    results.append(("13. POST /api/movies (Token User) -> Expect 403", s == 403, s, d))

    s, d = request("POST", "/movies", movie_payload, token=admin_token)
    created_movie_id = d.get("data", {}).get("id") if s == 201 else None
    results.append(("14. POST /api/movies (Token Admin) -> Expect 201", s == 201, s, d))

    # PUT movies
    put_movie_id = created_movie_id if created_movie_id else 1
    s, d = request("PUT", f"/movies/{put_movie_id}", {
        "title": f"AuthMovie_Up_{timestamp}",
        "releaseYear": 2024,
        "duration": 125,
        "categoryIds": [1]
    })
    results.append(("15. PUT /api/movies (Khong token) -> Expect 401", s == 401, s, d))

    s, d = request("PUT", f"/movies/{put_movie_id}", {
        "title": f"AuthMovie_Up_{timestamp}",
        "releaseYear": 2024,
        "duration": 125,
        "categoryIds": [1]
    }, token=user_token)
    results.append(("16. PUT /api/movies (Token User) -> Expect 403", s == 403, s, d))

    # DELETE movies
    del_movie_id = created_movie_id if created_movie_id else 999999
    s, d = request("DELETE", f"/movies/{del_movie_id}")
    results.append(("17. DELETE /api/movies (Khong token) -> Expect 401", s == 401, s, d))

    s, d = request("DELETE", f"/movies/{del_movie_id}", token=user_token)
    results.append(("18. DELETE /api/movies (Token User) -> Expect 403", s == 403, s, d))

    if created_movie_id:
        s, d = request("DELETE", f"/movies/{created_movie_id}", token=admin_token)
        results.append(("19. DELETE /api/movies (Token Admin) -> Expect 200", s == 200, s, d))

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
    print(f"Trang thai: {'TAT CA TEST PASSED (GREEN)' if all_passed else 'CO TEST THAT BAI (RED PHASE DUNG TIEN TRINH TDD)'}")
    return all_passed

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
