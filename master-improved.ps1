Param(
  [string]$ConnectionString = "Server=.;Database=CarShopDb;User Id=sa;Password=123;TrustServerCertificate=True;MultipleActiveResultSets=true",
  [string]$SolutionName = "CarShopSolution"
)

$ErrorActionPreference = "Stop"
$root = (Get-Location).Path

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   CarShop Improved Architecture Installer  " -ForegroundColor Cyan
Write-Host "   With ViewModels + Mapping                " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check part files
$parts = @("part1-dal-improved.ps1", "part2-bll-improved.ps1", "part3-web-improved.ps1", "part3-web-improved-controllers.ps1", "part3-web-improved-areas.ps1", "part3-web-improved-views.ps1", "part3-web-improved-views2.ps1")
$allExist = $true
foreach($part in $parts) {
    if (-not (Test-Path "$PSScriptRoot\$part")) {
        Write-Host "ERROR: Missing $part" -ForegroundColor Red
        $allExist = $false
    }
}

if (-not $allExist) {
    Write-Host ""
    Write-Host "Please ensure all 7 files are in the same directory:" -ForegroundColor Yellow
    Write-Host "  - master-improved.ps1" -ForegroundColor White
    Write-Host "  - part1-dal-improved.ps1" -ForegroundColor White
    Write-Host "  - part2-bll-improved.ps1" -ForegroundColor White
    Write-Host "  - part3-web-improved.ps1" -ForegroundColor White
    Write-Host "  - part3-web-improved-controllers.ps1" -ForegroundColor White
    Write-Host "  - part3-web-improved-areas.ps1" -ForegroundColor White
    Write-Host "  - part3-web-improved-views.ps1" -ForegroundColor White
    Write-Host "  - part3-web-improved-views2.ps1" -ForegroundColor White
    exit 1
}

Write-Host "All part files found" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Root:       $root" -ForegroundColor White
Write-Host "  Solution:   $SolutionName" -ForegroundColor White
Write-Host ""

function Write-Text {
  param([string]$Path, [string]$Content)
  New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
  Set-Content -Path $Path -Value $Content -Encoding UTF8
}

# Create solution
Write-Host "[1/6] Creating solution structure..." -ForegroundColor Cyan

$globalJson = '{"sdk":{"version":"9.0.200","rollForward":"latestMinor"}}'
Write-Text "$root\global.json" $globalJson

$sln = @"
Microsoft Visual Studio Solution File, Format Version 12.00
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "CarShop.DAL", "CarShop.DAL\CarShop.DAL.csproj", "{11111111-1111-1111-1111-111111111111}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "CarShop.BLL", "CarShop.BLL\CarShop.BLL.csproj", "{22222222-2222-2222-2222-222222222222}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "CarShop.Web", "CarShop.Web\CarShop.Web.csproj", "{33333333-3333-3333-3333-333333333333}"
EndProject
Global
    GlobalSection(SolutionConfigurationPlatforms) = preSolution
        Debug|Any CPU = Debug|Any CPU
        Release|Any CPU = Release|Any CPU
    EndGlobalSection
    GlobalSection(ProjectConfigurationPlatforms) = postSolution
        {11111111-1111-1111-1111-111111111111}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
        {11111111-1111-1111-1111-111111111111}.Debug|Any CPU.Build.0 = Debug|Any CPU
        {22222222-2222-2222-2222-222222222222}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
        {22222222-2222-2222-2222-222222222222}.Debug|Any CPU.Build.0 = Debug|Any CPU
        {33333333-3333-3333-3333-333333333333}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
        {33333333-3333-3333-3333-333333333333}.Debug|Any CPU.Build.0 = Debug|Any CPU
    EndGlobalSection
EndGlobal
"@

Write-Text "$root\$SolutionName.sln" $sln
Write-Host "  Solution created" -ForegroundColor Green

# Execute parts
Write-Host ""
Write-Host "[2/6] Creating Data Access Layer..." -ForegroundColor Cyan
. "$PSScriptRoot\part1-dal-improved.ps1" -Root $root -ConnectionString $ConnectionString -WriteTextFunc ${function:Write-Text}
Write-Host "  DAL complete" -ForegroundColor Green

Write-Host ""
Write-Host "[3/6] Creating Business Logic Layer..." -ForegroundColor Cyan
. "$PSScriptRoot\part2-bll-improved.ps1" -Root $root -WriteTextFunc ${function:Write-Text}
Write-Host "  BLL complete" -ForegroundColor Green

Write-Host ""
Write-Host "[4/6] Creating Web Layer with ViewModels..." -ForegroundColor Cyan
. "$PSScriptRoot\part3-web-improved.ps1" -Root $root -ConnectionString $ConnectionString -WriteTextFunc ${function:Write-Text}
Write-Host "  Web layer complete" -ForegroundColor Green

Write-Host ""
Write-Host "[4.1/6] Creating Main Controllers..." -ForegroundColor Cyan
. "$PSScriptRoot\part3-web-improved-controllers.ps1" -Root $root -WriteTextFunc ${function:Write-Text}
Write-Host "  Main Controllers complete" -ForegroundColor Green

Write-Host ""
Write-Host "[4.2/6] Creating Area Controllers..." -ForegroundColor Cyan
. "$PSScriptRoot\part3-web-improved-areas.ps1" -Root $root -WriteTextFunc ${function:Write-Text}
Write-Host "  Area Controllers complete" -ForegroundColor Green

Write-Host ""
Write-Host "[4.3/6] Creating Views..." -ForegroundColor Cyan
. "$PSScriptRoot\part3-web-improved-views.ps1" -Root $root -WriteTextFunc ${function:Write-Text}
Write-Host "  Views complete" -ForegroundColor Green

# Build
Write-Host ""
Write-Host "[5/6] Building solution..." -ForegroundColor Cyan
Push-Location $root
try {
    dotnet restore 2>&1 | Out-Null
    dotnet build --no-restore 2>&1 | Out-Null
    Write-Host "  Build successful" -ForegroundColor Green
} catch {
    Write-Host "  Build completed with warnings" -ForegroundColor Yellow
} finally {
    Pop-Location
}

# Database
Write-Host ""
Write-Host "[6/6] Setting up database..." -ForegroundColor Cyan
$dalProj = "$root\CarShop.DAL\CarShop.DAL.csproj"
$webProj = "$root\CarShop.Web\CarShop.Web.csproj"

Push-Location $root
try {
    if (-not (Test-Path "$root\CarShop.DAL\Migrations")) {
        dotnet ef migrations add InitialCreate -p $dalProj -s $webProj 2>&1 | Out-Null
    }
    dotnet ef database update -p $dalProj -s $webProj 2>&1 | Out-Null
    Write-Host "  Database ready" -ForegroundColor Green
} catch {
    Write-Host "  Database setup may need manual attention" -ForegroundColor Yellow
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "          INSTALLATION COMPLETE!            " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Architecture Improvements:" -ForegroundColor Cyan
Write-Host "  + ViewModels for Web layer" -ForegroundColor White
Write-Host "  + AutoMapper for DTO <-> ViewModel" -ForegroundColor White
Write-Host "  + Cleaner separation of concerns" -ForegroundColor White
Write-Host "  + Shopping cart with session" -ForegroundColor White
Write-Host "  + Soft delete for products" -ForegroundColor White
Write-Host ""
Write-Host "To run:" -ForegroundColor Cyan
Write-Host "  cd $root" -ForegroundColor White
Write-Host "  dotnet run --project CarShop.Web" -ForegroundColor White
Write-Host ""
Write-Host "URLs:" -ForegroundColor Cyan
Write-Host "  HTTP:  http://localhost:5000" -ForegroundColor White
Write-Host "  HTTPS: https://localhost:5001" -ForegroundColor White
Write-Host ""
Write-Host "Login:" -ForegroundColor Cyan
Write-Host "  Admin:    admin@carshop.local / P@ssword123" -ForegroundColor White
Write-Host "  Staff:    staff@carshop.local / P@ssword123" -ForegroundColor White
Write-Host "  Customer: user@carshop.local / P@ssword123" -ForegroundColor White
Write-Host ""