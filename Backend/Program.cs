using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using CineStream.Data;
using CineStream.Middleware;
using CineStream.Repositories.Implementations;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Implementations;
using CineStream.Services.Interfaces;
using CineStream.DTOs.Common;
using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);

// 1. Thêm Controllers với cấu hình chuẩn hóa phản hồi lỗi Validation & OpenAPI
builder.Services.AddControllers()
    .ConfigureApiBehaviorOptions(options =>
    {
        // Chuẩn hóa phản hồi lỗi ModelState Validation theo định dạng ApiResponse thống nhất
        options.InvalidModelStateResponseFactory = context =>
        {
            var errors = context.ModelState
                .Where(e => e.Value?.Errors.Count > 0)
                .SelectMany(e => e.Value!.Errors.Select(x => x.ErrorMessage))
                .ToList();
            var message = errors.FirstOrDefault() ?? "Du lieu dau vao khong hop le!";
            var response = ApiResponse<object>.Fail(message, errors);
            return new BadRequestObjectResult(response);
        };
    });
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
builder.Services.AddScoped<IMovieService, MovieService>();


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

// Cau hinh phat luong video tinh HLS (.m3u8 va .ts) voi MIME type chuan
var contentTypeProvider = new FileExtensionContentTypeProvider();
contentTypeProvider.Mappings[".m3u8"] = "application/vnd.apple.mpegurl";
contentTypeProvider.Mappings[".ts"] = "video/mp2t";

app.UseStaticFiles(new StaticFileOptions
{
    ContentTypeProvider = contentTypeProvider
});

// 9. Authentication PHẢI đứng trước Authorization
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// 10. Tự động nạp dữ liệu mẫu khi khởi động app
await DataSeeder.SeedAsync(app);

app.Run();
