import urllib.request
import urllib.error
import json
import sys
import time

sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "http://localhost:5182/api"

def request(method, path, payload=None, auth_header=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if auth_header is not None:
        headers["Authorization"] = auth_header
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

def run_deep_security_tests():
    print("================================================================================")
    print("   MA TRAN KIEM THU BAO MAT CHUYEN SAU (DEEP-DIVE SECURITY AUDIT MATRIX)")
    print("================================================================================")

    # 1. Dang nhap lay Token Admin va User
    s_admin, d_admin = request("POST", "/auth/login", {
        "usernameOrEmail": "admin@cinestream.com",
        "password": "Admin@123"
    })
    admin_token = d_admin.get("data", {}).get("token")
    admin_auth = f"Bearer {admin_token}" if admin_token else None

    s_user, d_user = request("POST", "/auth/login", {
        "usernameOrEmail": "user@cinestream.com",
        "password": "User@123"
    })
    user_token = d_user.get("data", {}).get("token")
    user_auth = f"Bearer {user_token}" if user_token else None

    print(f"Xac thuc Admin: HTTP {s_admin} | Token san sang: {'CO' if admin_token else 'KHONG'}")
    print(f"Xac thuc User:  HTTP {s_user} | Token san sang: {'CO' if user_token else 'KHONG'}")
    print("--------------------------------------------------------------------------------")

    results = []
    ts = int(time.time())

    # ==============================================================================
    # NHOM 1: QUYEN TRUY CAP CONG KHAI (PUBLIC ACCESS MATRIX - ANONYMOUS)
    # Khach vang lai / nguoi xem khong co token phai doc duoc danh sach va xem phim
    # ==============================================================================
    s, d = request("GET", "/categories")
    results.append(("1.1 Public GET /api/categories -> 200 OK", s == 200, s, d))

    s, d = request("GET", "/categories/1")
    results.append(("1.2 Public GET /api/categories/1 -> 200 OK", s == 200, s, d))

    s, d = request("GET", "/categories/999999")
    results.append(("1.3 Public GET /api/categories/999999 -> 404 Not Found", s == 404, s, d))

    s, d = request("GET", "/movies")
    results.append(("1.4 Public GET /api/movies -> 200 OK", s == 200, s, d))

    s, d = request("GET", "/movies?search=Quan&categoryId=1")
    results.append(("1.5 Public GET /api/movies (co bo loc) -> 200 OK", s == 200, s, d))

    s, d = request("GET", "/movies/1")
    results.append(("1.6 Public GET /api/movies/1 -> 200 OK", s == 200, s, d))

    s, d = request("GET", "/movies/1/playback")
    results.append(("1.7 Public GET /api/movies/1/playback (HLS Luong phat) -> 200 OK", s == 200, s, d))

    # ==============================================================================
    # NHOM 2: TAN CONG TOKEN GIA MAO / SAI DINH DANG (TAMPERED / MALFORMED TOKENS)
    # Server phai tu choi voi HTTP 401 Unauthorized, khong de xay ra loi 500
    # ==============================================================================
    fake_auth = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.payload"
    empty_auth = "Bearer "
    raw_auth = f"{admin_token}"  # Thieu tien to Bearer

    s, d = request("GET", "/auth/admin-check", auth_header=fake_auth)
    results.append(("2.1 Token gia mao goi /auth/admin-check -> 401 Unauthorized", s == 401, s, d))

    s, d = request("POST", "/categories", {"name": f"Fake_{ts}"}, auth_header=fake_auth)
    results.append(("2.2 Token gia mao POST /api/categories -> 401 Unauthorized", s == 401, s, d))

    s, d = request("POST", "/movies", {"title": f"Fake_{ts}", "categoryIds": [1]}, auth_header=fake_auth)
    results.append(("2.3 Token gia mao POST /api/movies -> 401 Unauthorized", s == 401, s, d))

    s, d = request("GET", "/auth/admin-check", auth_header=empty_auth)
    results.append(("2.4 Header Authorization rong 'Bearer ' -> 401 Unauthorized", s == 401, s, d))

    s, d = request("GET", "/auth/admin-check", auth_header=raw_auth)
    results.append(("2.5 Header thieu tien to 'Bearer ' -> 401 Unauthorized", s == 401, s, d))

    # ==============================================================================
    # NHOM 3: PHONG THU LEO THANG DAC QUYEN (PRIVILEGE ESCALATION DEFENSE)
    # User thuong hoan toan bi cam (HTTP 403 Forbidden) tren toan bo chuc nang Admin
    # ==============================================================================
    s, d = request("GET", "/auth/admin-check", auth_header=user_auth)
    results.append(("3.1 User thuong goi /auth/admin-check -> 403 Forbidden", s == 403, s, d))

    s, d = request("POST", "/categories", {"name": f"UserCat_{ts}"}, auth_header=user_auth)
    results.append(("3.2 User thuong POST /api/categories -> 403 Forbidden", s == 403, s, d))

    s, d = request("PUT", "/categories/1", {"name": f"UserCatUp_{ts}"}, auth_header=user_auth)
    results.append(("3.3 User thuong PUT /api/categories/1 -> 403 Forbidden", s == 403, s, d))

    s, d = request("DELETE", "/categories/1", auth_header=user_auth)
    results.append(("3.4 User thuong DELETE /api/categories/1 -> 403 Forbidden", s == 403, s, d))

    s, d = request("POST", "/movies", {"title": f"UserMov_{ts}", "categoryIds": [1]}, auth_header=user_auth)
    results.append(("3.5 User thuong POST /api/movies -> 403 Forbidden", s == 403, s, d))

    s, d = request("PUT", "/movies/1", {"title": f"UserMovUp_{ts}", "categoryIds": [1]}, auth_header=user_auth)
    results.append(("3.6 User thuong PUT /api/movies/1 -> 403 Forbidden", s == 403, s, d))

    s, d = request("DELETE", "/movies/1", auth_header=user_auth)
    results.append(("3.7 User thuong DELETE /api/movies/1 -> 403 Forbidden", s == 403, s, d))

    # ==============================================================================
    # NHOM 4: QUY TRINH QUAN TRI CHUAN (VALID ADMIN LIFECYCLE)
    # Admin co day du dac quyen tao moi, sua doi va xoa tren he thong
    # ==============================================================================
    s, d = request("GET", "/auth/admin-check", auth_header=admin_auth)
    results.append(("4.1 Admin hop le goi /auth/admin-check -> 200 OK", s == 200, s, d))

    # Tao the loai boi Admin
    cat_payload = {"name": f"AuditCat_{ts}", "description": "The loai audit"}
    s, d = request("POST", "/categories", cat_payload, auth_header=admin_auth)
    audit_cat_id = d.get("data", {}).get("id") if s == 201 else None
    results.append(("4.2 Admin POST /api/categories -> 201 Created", s == 201 and audit_cat_id is not None, s, d))

    # Cap nhat the loai boi Admin
    if audit_cat_id:
        s, d = request("PUT", f"/categories/{audit_cat_id}", {"name": f"AuditCat_Up_{ts}", "description": "Da sua"}, auth_header=admin_auth)
        results.append(("4.3 Admin PUT /api/categories/{id} -> 200 OK", s == 200, s, d))

        # Xoa the loai boi Admin
        s, d = request("DELETE", f"/categories/{audit_cat_id}", auth_header=admin_auth)
        results.append(("4.4 Admin DELETE /api/categories/{id} -> 200 OK", s == 200, s, d))

    # Tao phim boi Admin
    movie_payload = {
        "title": f"AuditMovie_{ts}",
        "releaseYear": 2025,
        "duration": 115,
        "categoryIds": [1]
    }
    s, d = request("POST", "/movies", movie_payload, auth_header=admin_auth)
    audit_movie_id = d.get("data", {}).get("id") if s == 201 else None
    results.append(("4.5 Admin POST /api/movies -> 201 Created", s == 201 and audit_movie_id is not None, s, d))

    # Cap nhat phim boi Admin
    if audit_movie_id:
        s, d = request("PUT", f"/movies/{audit_movie_id}", {
            "title": f"AuditMovie_Up_{ts}",
            "releaseYear": 2025,
            "duration": 120,
            "categoryIds": [1]
        }, auth_header=admin_auth)
        results.append(("4.6 Admin PUT /api/movies/{id} -> 200 OK", s == 200, s, d))

        # Xoa phim boi Admin
        s, d = request("DELETE", f"/movies/{audit_movie_id}", auth_header=admin_auth)
        results.append(("4.7 Admin DELETE /api/movies/{id} -> 200 OK", s == 200, s, d))

    # ==============================================================================
    # NHOM 5: PHONG THU DU LIEU NGAY CA VOI ADMIN (VALIDATION UNDER ADMIN)
    # Ke ca khi Admin gui payload sai, he thong van chan dung 400 Bad Request voi ApiResponse
    # ==============================================================================
    s, d = request("POST", "/categories", {"name": "   ", "description": "Rong"}, auth_header=admin_auth)
    is_400_env = (s == 400 and d.get("success") == False and d.get("message") is not None)
    results.append(("5.1 Admin gui ten the loai rong -> 400 Bad Request", is_400_env, s, d))

    s, d = request("POST", "/categories", {"name": "X" * 110}, auth_header=admin_auth)
    is_400_len = (s == 400 and d.get("success") == False)
    results.append(("5.2 Admin gui ten the loai > 100 ky tu -> 400 Bad Request", is_400_len, s, d))

    s, d = request("POST", "/movies", {"title": "   ", "categoryIds": [1]}, auth_header=admin_auth)
    is_400_title = (s == 400 and d.get("success") == False)
    results.append(("5.3 Admin gui tieu de phim rong -> 400 Bad Request", is_400_title, s, d))

    s, d = request("POST", "/movies", {"title": f"BadYear_{ts}", "releaseYear": 1750, "categoryIds": [1]}, auth_header=admin_auth)
    is_400_yr = (s == 400 and d.get("success") == False)
    results.append(("5.4 Admin gui nam phat hanh < 1888 -> 400 Bad Request", is_400_yr, s, d))

    s, d = request("POST", "/movies", {"title": f"BadDur_{ts}", "duration": -50, "categoryIds": [1]}, auth_header=admin_auth)
    is_400_dur = (s == 400 and d.get("success") == False)
    results.append(("5.5 Admin gui thoi luong am -> 400 Bad Request", is_400_dur, s, d))

    # ==============================================================================
    # NHOM 6: CO LAP DANH TINH NGUOI DUNG (IDENTITY ISOLATION)
    # ==============================================================================
    s_me_u, d_me_u = request("GET", "/auth/me", auth_header=user_auth)
    u_role = d_me_u.get("data", {}).get("role")
    results.append(("6.1 User GET /api/auth/me tra ve dung Role User (0)", s_me_u == 200 and u_role == 0, s_me_u, d_me_u))

    s_me_a, d_me_a = request("GET", "/auth/me", auth_header=admin_auth)
    a_role = d_me_a.get("data", {}).get("role")
    results.append(("6.2 Admin GET /api/auth/me tra ve dung Role Admin (1)", s_me_a == 200 and a_role == 1, s_me_a, d_me_a))

    # TONG KET
    print("\n--- KET QUA CHI TIET TUNG KICH BAN AN NINH ---")
    all_passed = True
    passed_count = 0
    for name, passed, status, resp in results:
        mark = "[PASS]" if passed else "[FAIL]"
        if passed:
            passed_count += 1
        else:
            all_passed = False
        print(f"{mark} {name} (HTTP: {status})")
        if not passed:
            print(f"       -> Phan hoi bat thuong: {resp}")

    print("\n================================================================================")
    print(f"TONG KET AUDIT: {passed_count}/{len(results)} KICH BAN BAO MAT DAT CHUAN TUYET DOI ({'HOAN HAO' if all_passed else 'CO LOI'})")
    print("================================================================================")
    return all_passed

if __name__ == "__main__":
    success = run_deep_security_tests()
    sys.exit(0 if success else 1)
