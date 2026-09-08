using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using CineStream.Models;
using CineStream.Services.Interfaces;

namespace CineStream.Services.Implementations;

public class JwtService : IJwtService
{
    private readonly IConfiguration _configuration;

    public JwtService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GenerateToken(User user)
    {
        // 1. Đọc các thông số từ appsettings.json
        var jwtKey = _configuration["JWT:Key"] ?? "your-super-secret-key-at-least-32-characters-long";
        var jwtIssuer = _configuration["JWT:Issuer"] ?? "CineStream";
        var jwtAudience = _configuration["JWT:Audience"] ?? "CineStreamApp";
        var expireMinutes = double.Parse(_configuration["JWT:ExpireMinutes"] ?? "60");

        // 2. Đóng gói danh tính người dùng vào Claims
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role.ToString())
        };

        // 3. Khóa bí mật dùng để ký (chỉ server mới có chìa khóa này)
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        // 4. Mô tả thông tin token (Ai phát hành, ai nhận, hạn dùng bao lâu, kèm chữ ký)
        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(expireMinutes),
            Issuer = jwtIssuer,
            Audience = jwtAudience,
            SigningCredentials = creds
        };

        // 5. Xuất chuỗi Token hoàn chỉnh dạng chuỗi (Header.Payload.Signature)
        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }
}
