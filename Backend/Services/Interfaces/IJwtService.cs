using CineStream.Models;

namespace CineStream.Services.Interfaces;

public interface IJwtService
{
    string GenerateToken(User user);
}
