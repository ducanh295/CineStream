using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using CineStream.Data;
using CineStream.Middleware;
using CineStream.Repositories.Implementations;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Implementations;
using CineStream.Services.Interfaces;

var builder = WebApplication.CreateBuilder(args);

// 1. Thêm Controllers & OpenAPI
builder.Services.AddControllers();
builder.Services.AddOpenApi();

// 2. Kết nối Database PostgreSQL
builder.Services.AddDbContext<AppDbContext>(options => 
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// 3. Đăng ký Repositories (DI)
builder.Services.AddScoped<ICategoryRepository, CategoryRepository>();
builder.Services.AddScoped<IMovieRepository, MovieRepository>();
builder.Services.AddScoped<ISeriesRepository, SeriesRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IFavoriteRepository, FavoriteRepository>();

// 4. Đăng ký Services (DI)
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();

// 5. Cấu hình JWT Authentication
var jwtKey = builder.Configuration["JWT:Key"] ?? "your-super-secret-key-at-least-32-characters-long";
var jwtIssuer = builder.Configuration["JWT:Issuer"] ?? "CineStream";
var jwtAudience = builder.Configuration["JWT:Audience"] ?? "CineStreamApp";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };
});

// 6. Cấu hình CORS cho Frontend (Flutter + React Admin)
builder.Services.AddCors(option =>
{
    option.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

// 7. Global Exception Middleware
app.UseMiddleware<ExceptionHandlingMiddleware>();

// 8. Scalar API Reference (Giao diện trực quan OpenAPI thay Swagger)
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(options =>
    {
        options.WithTitle("CineStream API Reference")
               .WithTheme(ScalarTheme.Moon);
    });
}

app.UseHttpsRedirection();
app.UseCors("AllowAll");

// 9. Authentication PHẢI đứng trước Authorization
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// 10. Tự động nạp dữ liệu mẫu khi khởi động app
await DataSeeder.SeedAsync(app);

app.Run();
