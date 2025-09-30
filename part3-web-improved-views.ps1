Param(
  [string]$Root,
  [scriptblock]$WriteTextFunc
)

# Shared Views
$viewImports = @'
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
@using CarShop.DAL.Entities
@using CarShop.Web.ViewModels
@using Microsoft.AspNetCore.Identity
@inject SignInManager<ApplicationUser> SignInManager
@inject UserManager<ApplicationUser> UserManager
'@

$viewStart = '@{ Layout = "_Layout"; }'

$layout = @'
@{ 
    var isAuth = User?.Identity?.IsAuthenticated ?? false;
    var isAdmin = User.IsInRole("Admin");
    var isStaff = User.IsInRole("Staff");
    var isCustomer = User.IsInRole("Customer");
}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>CarShop - Premium Auto Marketplace</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet" />
    <link href="~/css/site.css" rel="stylesheet" />
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark sticky-top">
        <div class="container">
            <a class="navbar-brand fw-bold" href="/">
                <i class="bi bi-car-front-fill"></i> CarShop
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="/Cars"><i class="bi bi-grid-3x3-gap"></i> Browse Cars</a>
                    </li>
                    @if(isAuth)
                    {
                        <li class="nav-item">
                            <a class="nav-link" href="/Dashboard"><i class="bi bi-speedometer2"></i> Dashboard</a>
                        </li>
                        @if(isCustomer)
                        {
                            <li class="nav-item">
                                <a class="nav-link" href="/Cart"><i class="bi bi-cart"></i> Cart</a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link" href="/Orders/History"><i class="bi bi-bag-check"></i> Orders</a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link" href="/TestDrive/My"><i class="bi bi-calendar-check"></i> Test Drives</a>
                            </li>
                        }
                        @if(isStaff || isAdmin)
                        {
                            <li class="nav-item">
                                <a class="nav-link" href="/Staff/Inventory"><i class="bi bi-box-seam"></i> Inventory</a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link" href="/Staff/Appointments"><i class="bi bi-calendar2-check"></i> Appointments</a>
                            </li>
                        }
                        @if(isAdmin)
                        {
                            <li class="nav-item">
                                <a class="nav-link" href="/Admin/Cars"><i class="bi bi-gear"></i> Manage Cars</a>
                            </li>
                        }
                    }
                </ul>
                <ul class="navbar-nav">
                    @if(!isAuth)
                    {
                        <li class="nav-item">
                            <a class="nav-link" href="/Account/Login"><i class="bi bi-box-arrow-in-right"></i> Login</a>
                        </li>
                        <li class="nav-item">
                            <a class="btn btn-outline-light btn-sm ms-2" href="/Account/Register">Sign Up</a>
                        </li>
                    }
                    else
                    {
                        <li class="nav-item dropdown">
                            <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown">
                                <i class="bi bi-person-circle"></i> @User.Identity!.Name
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end">
                                <li><a class="dropdown-item" href="/Dashboard">Dashboard</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="/Account/Logout">Logout</a></li>
                            </ul>
                        </li>
                    }
                </ul>
            </div>
        </div>
    </nav>

    <main>
        @if(TempData["Message"] != null)
        {
            <div class="container mt-3">
                <div class="alert alert-success alert-dismissible fade show">
                    <i class="bi bi-check-circle"></i> @TempData["Message"]
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </div>
        }
        @if(TempData["Error"] != null)
        {
            <div class="container mt-3">
                <div class="alert alert-danger alert-dismissible fade show">
                    <i class="bi bi-exclamation-circle"></i> @TempData["Error"]
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </div>
        }
        @RenderBody()
    </main>

    <footer class="footer mt-5 py-4">
        <div class="container text-center">
            <p class="mb-0">&copy; 2025 CarShop. All rights reserved.</p>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
'@

$siteCss = @'
:root {
    --primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    --dark-gradient: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
}

body {
    font-family: "Segoe UI", system-ui, -apple-system, sans-serif;
    background: #f8f9fa;
}

.navbar {
    background: var(--dark-gradient);
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.hero-section {
    background: var(--primary-gradient);
    color: white;
    min-height: 70vh;
    display: flex;
    align-items: center;
}

.feature-card {
    padding: 2rem;
    background: white;
    border-radius: 15px;
    box-shadow: 0 5px 15px rgba(0,0,0,0.08);
    transition: transform 0.3s;
}

.feature-card:hover {
    transform: translateY(-5px);
}

.feature-icon {
    font-size: 3rem;
    background: var(--primary-gradient);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}

.car-card {
    background: white;
    border-radius: 15px;
    overflow: hidden;
    box-shadow: 0 5px 15px rgba(0,0,0,0.08);
    transition: transform 0.3s;
    height: 100%;
}

.car-card:hover {
    transform: translateY(-10px);
}

.car-image {
    height: 250px;
    overflow: hidden;
    position: relative;
}

.car-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s;
}

.car-card:hover .car-image img {
    transform: scale(1.1);
}

.btn-primary {
    background: var(--primary-gradient);
    border: none;
    padding: 0.6rem 1.5rem;
    transition: transform 0.2s;
}

.btn-primary:hover {
    transform: translateY(-2px);
}

.footer {
    background: var(--dark-gradient);
    color: white;
}

.card {
    border: none;
    border-radius: 15px;
}
'@

$homeIndex = @'
<div class="hero-section">
    <div class="container">
        <div class="row align-items-center" style="min-height: 75vh;">
            <div class="col-lg-6">
                <h1 class="display-3 fw-bold mb-4">
                    Find Your Dream Car Today
                </h1>
                <p class="lead mb-4">
                    Browse our curated selection of premium vehicles. 
                    Schedule test drives and complete purchases online.
                </p>
                <div class="d-flex gap-3">
                    <a href="/Cars" class="btn btn-primary btn-lg">
                        <i class="bi bi-search"></i> Explore Inventory
                    </a>
                    <a href="/Account/Register" class="btn btn-outline-light btn-lg">
                        Get Started
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="container py-5">
    <div class="row g-4">
        <div class="col-md-4">
            <div class="feature-card text-center">
                <i class="bi bi-shield-check feature-icon"></i>
                <h3>Verified Vehicles</h3>
                <p>All cars inspected and certified</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="feature-card text-center">
                <i class="bi bi-calendar-check feature-icon"></i>
                <h3>Easy Test Drives</h3>
                <p>Book appointments online</p>
            </div>
        </div>
        <div class="col-md-4">
            <div class="feature-card text-center">
                <i class="bi bi-credit-card feature-icon"></i>
                <h3>Secure Checkout</h3>
                <p>Safe payment processing</p>
            </div>
        </div>
    </div>
</div>
'@

$carsIndex = @'
@model List<CarListViewModel>
@{
    var total = (int)ViewBag.Total;
    var page = (int)ViewBag.Page;
    var size = (int)ViewBag.PageSize;
    int totalPages = (int)Math.Ceiling(total / (double)size);
}

<div class="container py-5">
    <h1 class="mb-4">Browse Our Collection</h1>
    
    <form method="get" class="card shadow-sm mb-4">
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-5">
                    <input name="search" value="@ViewBag.Search" class="form-control" 
                           placeholder="Search by name or description..." />
                </div>
                <div class="col-md-3">
                    <input name="brand" value="@ViewBag.Brand" class="form-control" 
                           placeholder="Filter by brand..." />
                </div>
                <div class="col-md-2">
                    <button class="btn btn-primary w-100" type="submit">
                        <i class="bi bi-search"></i> Search
                    </button>
                </div>
                <div class="col-md-2">
                    <a href="/Cars" class="btn btn-outline-secondary w-100">
                        <i class="bi bi-x-circle"></i> Clear
                    </a>
                </div>
            </div>
        </div>
    </form>

    <div class="row g-4">
        @foreach(var car in Model)
        {
            <div class="col-md-4">
                <div class="car-card">
                    <div class="car-image">
                        <img src="@(string.IsNullOrEmpty(car.ImagePath) ? "https://placehold.co/600x400?text=" + car.Name : car.ImagePath)" 
                             alt="@car.Name" />
                        @if(car.Stock > 0)
                        {
                            <span class="badge bg-success position-absolute top-0 end-0 m-3">In Stock</span>
                        }
                        else
                        {
                            <span class="badge bg-danger position-absolute top-0 end-0 m-3">Out of Stock</span>
                        }
                    </div>
                    <div class="card-body">
                        <h5 class="card-title">@car.Name</h5>
                        <p class="text-muted mb-2">
                            <i class="bi bi-building"></i> @car.Brand
                        </p>
                        <p class="text-truncate small">@car.Description</p>
                        <div class="d-flex justify-content-between align-items-center">
                            <h4 class="text-primary mb-0">@car.Price.ToString("C")</h4>
                            <a href="/Cars/Details/@car.Id" class="btn btn-outline-primary">
                                View Details <i class="bi bi-arrow-right"></i>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        }
    </div>

    @if(totalPages > 1)
    {
        <nav class="mt-5">
            <ul class="pagination justify-content-center">
                @for(int i = 1; i <= totalPages; i++)
                {
                    <li class="page-item @(i == page ? "active" : "")">
                        <a class="page-link" href="?page=@i&search=@ViewBag.Search&brand=@ViewBag.Brand">@i</a>
                    </li>
                }
            </ul>
        </nav>
    }
</div>
'@

# Continue in next part due to length limit...

& $WriteTextFunc -Path "$Root\CarShop.Web\Views\_ViewImports.cshtml" -Content $viewImports
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\_ViewStart.cshtml" -Content $viewStart
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\Shared\_Layout.cshtml" -Content $layout
& $WriteTextFunc -Path "$Root\CarShop.Web\wwwroot\css\site.css" -Content $siteCss
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\Home\Index.cshtml" -Content $homeIndex
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\Cars\Index.cshtml" -Content $carsIndex

Write-Host "  Base views created, calling next part..." -ForegroundColor White

# Call next part for remaining views
. "$PSScriptRoot\part3-web-improved-views2.ps1" -Root $Root -WriteTextFunc $WriteTextFunc