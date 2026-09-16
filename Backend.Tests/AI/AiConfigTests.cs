using System;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Xunit;
using CineStream.Data;
using CineStream.DTOs.AI;
using CineStream.Models;
using CineStream.Services.Implementations;

namespace Backend.Tests.AI;

// Bộ kiểm thử đơn vị TDD cho chức năng CRUD cấu hình Gemini API Key của Chatbot
public class AiConfigTests
{
    private readonly AppDbContext _context;
    private readonly IOptions<GeminiOptions> _options;

    public AiConfigTests()
    {
        var dbOptions = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: $"AiConfigTestDb_{Guid.NewGuid()}")
            .Options;

        _context = new AppDbContext(dbOptions);

        _options = Options.Create(new GeminiOptions
        {
            ApiKey = "DEFAULT_CONFIG_KEY_123456",
            Model = "gemini-3.5-flash-lite",
            BaseUrl = "https://generativelanguage.googleapis.com/v1beta"
        });
    }

    [Fact]
    public async Task GetAiConfigAsync_NoDatabaseOverride_ReturnsDefaultConfigFromAppSettings()
    {
        // Arrange
        var service = new AIService(_context, new HttpClient(), _options, NullLogger<AIService>.Instance);

        // Act
        var result = await service.GetAiConfigAsync();

        // Assert
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.NotNull(result.Data);
        Assert.Equal("DEFAULT_CONFIG_KEY_123456", result.Data.ApiKey);
        Assert.False(result.Data.IsCustom);
        Assert.Equal("gemini-3.5-flash-lite", result.Data.Model);
        Assert.Equal("DEFA...3456", result.Data.MaskedApiKey);
    }

    [Fact]
    public async Task UpdateAiConfigAsync_ValidKey_SavesToDatabaseAndReturnsUpdatedConfig()
    {
        // Arrange
        var service = new AIService(_context, new HttpClient(), _options, NullLogger<AIService>.Instance);
        var request = new UpdateAiConfigRequestDto
        {
            ApiKey = "CUSTOM_NEW_GEMINI_KEY_999888",
            Model = "gemini-1.5-pro"
        };

        // Act
        var result = await service.UpdateAiConfigAsync(request);

        // Assert
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.NotNull(result.Data);
        Assert.Equal("CUSTOM_NEW_GEMINI_KEY_999888", result.Data.ApiKey);
        Assert.True(result.Data.IsCustom);
        Assert.Equal("gemini-1.5-pro", result.Data.Model);

        // Đối soát trực tiếp trong cơ sở dữ liệu
        var savedKey = await _context.SystemSettings.FirstOrDefaultAsync(s => s.Key == "Gemini:ApiKey");
        Assert.NotNull(savedKey);
        Assert.Equal("CUSTOM_NEW_GEMINI_KEY_999888", savedKey.Value);
    }

    [Fact]
    public async Task DeleteAiConfigAsync_CustomKeyExists_ResetsToDefaultConfig()
    {
        // Arrange
        var service = new AIService(_context, new HttpClient(), _options, NullLogger<AIService>.Instance);
        _context.SystemSettings.Add(new SystemSetting
        {
            Key = "Gemini:ApiKey",
            Value = "TEMPORARY_KEY_TO_DELETE"
        });
        _context.SystemSettings.Add(new SystemSetting
        {
            Key = "Gemini:Model",
            Value = "gemini-custom"
        });
        await _context.SaveChangesAsync();

        // Act
        var deleteResult = await service.DeleteAiConfigAsync();
        var configAfterDelete = await service.GetAiConfigAsync();

        // Assert
        Assert.True(deleteResult.Success);
        Assert.NotNull(configAfterDelete.Data);
        Assert.False(configAfterDelete.Data.IsCustom);
        Assert.Equal("DEFAULT_CONFIG_KEY_123456", configAfterDelete.Data.ApiKey);
    }
}
