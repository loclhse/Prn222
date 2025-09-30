Param(
  [string]$Root,
  [string]$ConnectionString,
  [scriptblock]$WriteTextFunc
)

# Web Project
$webCsproj = @'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <UserSecretsId>carshop-web</UserSecretsId>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="9.0.0">
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="Microsoft.AspNetCore.Identity.EntityFrameworkCore" Version="9.0.0" />
    <PackageReference Include="Microsoft.AspNetCore.Identity.UI" Version="9.0.0" />
    <PackageReference Include="AutoMapper" Version="12.0.1" />
    <PackageReference Include="AutoMapper.Extensions.Microsoft.DependencyInjection" Version="12.0.1" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\CarShop.BLL\CarShop.BLL.csproj" />
    <ProjectReference Include="..\CarShop.DAL\CarShop.DAL.csproj" />
  </ItemGroup>
</Project>
'@

$webAppsettings = (@{
  Logging = @{ LogLevel = @{ Default = "Information"; "Microsoft.AspNetCore" = "Warning" } }
  AllowedHosts = "*"
  ConnectionStrings = @{ DefaultConnection = $ConnectionString }
} | ConvertTo-Json -Depth 10)

$launchSettings = @'
{
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "applicationUrl": "http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "applicationUrl": "https://localhost:5001;http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
'@

# ViewModels
$carViewModel = @'
using System.ComponentModel.DataAnnotations;

namespace CarShop.Web.ViewModels
{
    public class CarViewModel
    {
        public int Id { get; set; }
        
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [StringLength(50)]
        public string Brand { get; set; } = string.Empty;
        
        [Required]
        [Range(0, 999999999)]
        public decimal Price { get; set; }
        
        [Required]
        [Range(0, 9999)]
        public int Stock { get; set; }
        
        public string? ImagePath { get; set; }
        
        [StringLength(500)]
        public string? Description { get; set; }
        
        public bool IsActive { get; set; }
    }
    
    public class CarListViewModel
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int Stock { get; set; }
        public string? ImagePath { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }
    
    public class CarDetailViewModel
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int Stock { get; set; }
        public string? ImagePath { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }
}
'@

$cartViewModel = @'
namespace CarShop.Web.ViewModels
{
    public class CartItemViewModel
    {
        public int CarId { get; set; }
        public string CarName { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int Quantity { get; set; }
        public string? ImagePath { get; set; }
        public int Stock { get; set; }
        public decimal Subtotal => Price * Quantity;
    }
    
    public class AddToCartViewModel
    {
        public int CarId { get; set; }
        public int Quantity { get; set; } = 1;
    }
}
'@

$orderViewModel = @'
namespace CarShop.Web.ViewModels
{
    public class OrderViewModel
    {
        public int Id { get; set; }
        public DateTime CreatedAt { get; set; }
        public decimal Total { get; set; }
        public string Status { get; set; } = string.Empty;
        public List<OrderItemViewModel> Items { get; set; } = new();
    }
    
    public class OrderItemViewModel
    {
        public int CarId { get; set; }
        public string CarName { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal Subtotal => Quantity * UnitPrice;
    }
}
'@

$testDriveViewModel = @'
using System.ComponentModel.DataAnnotations;

namespace CarShop.Web.ViewModels
{
    public class TestDriveViewModel
    {
        public int Id { get; set; }
        public int CarId { get; set; }
        public string CarName { get; set; } = string.Empty;
        public DateTime ScheduledAt { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? Notes { get; set; }
    }
    
    public class CreateTestDriveViewModel
    {
        [Required]
        public int CarId { get; set; }
        
        [Required]
        public DateTime ScheduledAt { get; set; }
        
        [StringLength(500)]
        public string? Notes { get; set; }
    }
}
'@

$accountViewModel = @'
using System.ComponentModel.DataAnnotations;

namespace CarShop.Web.ViewModels
{
    public class RegisterViewModel
    {
        [Required]
        [EmailAddress]
        [Display(Name = "Email")]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100)]
        [Display(Name = "Full Name")]
        public string FullName { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100, MinimumLength = 6)]
        [DataType(DataType.Password)]
        [Display(Name = "Password")]
        public string Password { get; set; } = string.Empty;
    }
    
    public class LoginViewModel
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [DataType(DataType.Password)]
        public string Password { get; set; } = string.Empty;
    }
}
'@

# Web Mapping Profile (DTO <-> ViewModel)
$webMappingProfile = @'
using AutoMapper;
using CarShop.BLL.DTOs;
using CarShop.Web.ViewModels;

namespace CarShop.Web.Mappings
{
    public class WebMappingProfile : Profile
    {
        public WebMappingProfile()
        {
            // Car mappings
            CreateMap<CarDto, CarViewModel>().ReverseMap();
            CreateMap<CarDto, CarListViewModel>();
            CreateMap<CarDto, CarDetailViewModel>();
            
            // Order mappings
            CreateMap<OrderDto, OrderViewModel>();
            CreateMap<OrderItemDto, OrderItemViewModel>();
            
            // TestDrive mappings
            CreateMap<TestDriveDto, TestDriveViewModel>();
            CreateMap<CreateTestDriveViewModel, TestDriveDto>();
        }
    }
}
'@

# Program.cs with Session support
$programCs = @'
using CarShop.BLL;
using CarShop.BLL.Services;
using CarShop.DAL;
using CarShop.DAL.Entities;
using CarShop.Web.Mappings;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddIdentity<ApplicationUser, IdentityRole>(o => {
    o.SignIn.RequireConfirmedAccount = false;
    o.Password.RequireDigit = true;
    o.Password.RequiredLength = 6;
}).AddEntityFrameworkStores<AppDbContext>()
  .AddDefaultTokenProviders()
  .AddDefaultUI();

builder.Services.ConfigureApplicationCookie(o => {
    o.LoginPath = "/Account/Login";
    o.LogoutPath = "/Account/Logout";
    o.AccessDeniedPath = "/Account/AccessDenied";
});

// Session for shopping cart
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

builder.Services.AddControllersWithViews(o => {
    o.Filters.Add(new AutoValidateAntiforgeryTokenAttribute());
});

// AutoMapper for both BLL and Web layers
builder.Services.AddAutoMapper(typeof(MappingProfile), typeof(WebMappingProfile));

// Services
builder.Services.AddScoped<ICarService, CarService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<ITestDriveService, TestDriveService>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    await Seeder.SeedAsync(scope.ServiceProvider);
}

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseSession();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "areas",
    pattern: "{area:exists}/{controller=Home}/{action=Index}/{id?}");

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
'@

# Write initial files
& $WriteTextFunc -Path "$Root\CarShop.Web\CarShop.Web.csproj" -Content $webCsproj
& $WriteTextFunc -Path "$Root\CarShop.Web\appsettings.json" -Content $webAppsettings
& $WriteTextFunc -Path "$Root\CarShop.Web\Properties\launchSettings.json" -Content $launchSettings
& $WriteTextFunc -Path "$Root\CarShop.Web\Program.cs" -Content $programCs
& $WriteTextFunc -Path "$Root\CarShop.Web\ViewModels\CarViewModel.cs" -Content $carViewModel
& $WriteTextFunc -Path "$Root\CarShop.Web\ViewModels\CartViewModel.cs" -Content $cartViewModel
& $WriteTextFunc -Path "$Root\CarShop.Web\ViewModels\OrderViewModel.cs" -Content $orderViewModel
& $WriteTextFunc -Path "$Root\CarShop.Web\ViewModels\TestDriveViewModel.cs" -Content $testDriveViewModel
& $WriteTextFunc -Path "$Root\CarShop.Web\ViewModels\AccountViewModel.cs" -Content $accountViewModel
& $WriteTextFunc -Path "$Root\CarShop.Web\Mappings\WebMappingProfile.cs" -Content $webMappingProfile

Write-Host "  ViewModels and Mappings created" -ForegroundColor White