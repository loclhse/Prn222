Param(
  [string]$Root,
  [scriptblock]$WriteTextFunc
)

# Cars Details View
$carsDetails = @'
@model CarDetailViewModel

<div class="container py-5">
    <div class="row">
        <div class="col-lg-6 mb-4">
            <img src="@(string.IsNullOrEmpty(Model.ImagePath) ? "https://placehold.co/800x600?text=" + Model.Name : Model.ImagePath)" 
                 class="img-fluid rounded shadow" alt="@Model.Name" 
                 style="@(ViewBag.IsInactive == true ? "opacity: 0.5; filter: grayscale(100%);" : "")" />
        </div>
        <div class="col-lg-6">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="/Cars">Cars</a></li>
                    <li class="breadcrumb-item active">@Model.Name</li>
                </ol>
            </nav>
            
            @if(ViewBag.IsInactive == true)
            {
                <div class="alert alert-warning mb-4">
                    <i class="bi bi-exclamation-triangle"></i>
                    <strong>This product is no longer active.</strong> 
                    It may be out of stock or discontinued.
                </div>
            }
            
            <h1 class="display-4 mb-3">@Model.Name</h1>
            <p class="lead text-muted mb-4">
                <i class="bi bi-building"></i> @Model.Brand
            </p>
            
            <div class="card shadow-sm mb-4">
                <div class="card-body">
                    <h2 class="text-primary mb-0">@Model.Price.ToString("C")</h2>
                    <p class="text-muted mb-3">
                        <i class="bi bi-box-seam"></i> Stock: <strong>@Model.Stock units</strong>
                    </p>
                    <p>@Model.Description</p>
                </div>
            </div>

            @if(ViewBag.IsInactive == true)
            {
                <div class="alert alert-secondary">
                    <i class="bi bi-info-circle"></i> This product cannot be purchased at this time.
                </div>
            }
            else if(User.IsInRole("Customer"))
            {
                <div class="card shadow-sm mb-3">
                    <div class="card-body">
                        <h5><i class="bi bi-bag-check"></i> Add to Cart</h5>
                        <form method="post" asp-controller="Cart" asp-action="AddToCart">
                            <input type="hidden" asp-for="Id" name="CarId" />
                            <div class="mb-3">
                                <label class="form-label">Quantity</label>
                                <input type="number" name="Quantity" value="1" min="1" max="@Model.Stock" 
                                       class="form-control" @(Model.Stock == 0 ? "disabled" : "") />
                            </div>
                            <button class="btn btn-primary w-100" type="submit" @(Model.Stock == 0 ? "disabled" : "")>
                                <i class="bi bi-cart-plus"></i> Add to Cart
                            </button>
                        </form>
                    </div>
                </div>
                
                <div class="card shadow-sm">
                    <div class="card-body">
                        <h5><i class="bi bi-calendar-check"></i> Schedule Test Drive</h5>
                        <form method="post" asp-controller="TestDrive" asp-action="Create">
                            <input type="hidden" asp-for="Id" name="CarId" />
                            <div class="mb-3">
                                <label class="form-label">Preferred Date & Time</label>
                                <input type="datetime-local" name="ScheduledAt" class="form-control" required 
                                       min="@DateTime.Now.ToString("yyyy-MM-ddTHH:mm")" />
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Notes (Optional)</label>
                                <textarea name="Notes" class="form-control" rows="2" 
                                          placeholder="Any specific requirements..."></textarea>
                            </div>
                            <button class="btn btn-primary w-100" type="submit">
                                <i class="bi bi-calendar-plus"></i> Book Test Drive
                            </button>
                        </form>
                    </div>
                </div>
            }
            else
            {
                <div class="alert alert-info">
                    <i class="bi bi-info-circle"></i> 
                    <a href="/Account/Login">Login</a> as a customer to purchase or schedule test drives.
                </div>
            }
        </div>
    </div>
</div>
'@

# Cart View
$cartIndex = @'
@model List<CartItemViewModel>

<div class="container py-5">
    <h1 class="mb-4"><i class="bi bi-cart"></i> Shopping Cart</h1>
    
    @if(!Model.Any())
    {
        <div class="alert alert-info">
            <i class="bi bi-info-circle"></i> Your cart is empty.
            <a href="/Cars" class="alert-link">Continue shopping</a>
        </div>
    }
    else
    {
        <div class="row">
            <div class="col-lg-8">
                @foreach(var item in Model)
                {
                    <div class="card mb-3">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-2">
                                    <img src="@(string.IsNullOrEmpty(item.ImagePath) ? "https://placehold.co/150x100" : item.ImagePath)" 
                                         class="img-fluid rounded" alt="@item.CarName" />
                                </div>
                                <div class="col-md-4">
                                    <h5>@item.CarName</h5>
                                    <p class="text-muted mb-0">@item.Brand</p>
                                </div>
                                <div class="col-md-2">
                                    <strong>@item.Price.ToString("C")</strong>
                                </div>
                                <div class="col-md-2">
                                    <form method="post" asp-action="UpdateQuantity">
                                        <input type="hidden" name="carId" value="@item.CarId" />
                                        <input type="number" name="quantity" value="@item.Quantity" 
                                               min="1" max="@item.Stock" class="form-control form-control-sm" 
                                               onchange="this.form.submit()" />
                                    </form>
                                </div>
                                <div class="col-md-2 text-end">
                                    <div><strong>@item.Subtotal.ToString("C")</strong></div>
                                    <form method="post" asp-action="RemoveFromCart" class="d-inline">
                                        <input type="hidden" name="carId" value="@item.CarId" />
                                        <button class="btn btn-sm btn-outline-danger mt-2" type="submit">
                                            <i class="bi bi-trash"></i> Remove
                                        </button>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                }
            </div>
            
            <div class="col-lg-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Order Summary</h5>
                        <hr />
                        <div class="d-flex justify-content-between mb-2">
                            <span>Subtotal:</span>
                            <strong>@Model.Sum(x => x.Subtotal).ToString("C")</strong>
                        </div>
                        <div class="d-flex justify-content-between mb-3">
                            <span>Total Items:</span>
                            <strong>@Model.Sum(x => x.Quantity)</strong>
                        </div>
                        <hr />
                        <form method="post" asp-action="Checkout">
                            <button class="btn btn-success w-100" type="submit">
                                <i class="bi bi-credit-card"></i> Proceed to Checkout
                            </button>
                        </form>
                        <a href="/Cars" class="btn btn-outline-secondary w-100 mt-2">
                            Continue Shopping
                        </a>
                    </div>
                </div>
            </div>
        </div>
    }
</div>
'@

# Orders History
$ordersHistory = @'
@model List<OrderViewModel>

<div class="container py-5">
    <h1 class="mb-4"><i class="bi bi-bag-check"></i> My Orders</h1>
    
    @if(!Model.Any())
    {
        <div class="alert alert-info">
            <i class="bi bi-info-circle"></i> You haven't placed any orders yet.
            <a href="/Cars" class="alert-link">Browse our inventory</a> to get started!
        </div>
    }
    else
    {
        @foreach(var order in Model)
        {
            <div class="card shadow-sm mb-4">
                <div class="card-header bg-primary text-white">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h5 class="mb-0">Order #@order.Id</h5>
                            <small>@order.CreatedAt.ToString("MMMM dd, yyyy h:mm tt")</small>
                        </div>
                        <span class="badge bg-light text-dark fs-6">@order.Status</span>
                    </div>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Car</th>
                                    <th>Quantity</th>
                                    <th>Unit Price</th>
                                    <th class="text-end">Subtotal</th>
                                    <th></th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach(var item in order.Items)
                                {
                                    <tr>
                                        <td><strong>@item.CarName</strong></td>
                                        <td><span class="badge bg-secondary">@item.Quantity</span></td>
                                        <td>@item.UnitPrice.ToString("C")</td>
                                        <td class="text-end"><strong>@item.Subtotal.ToString("C")</strong></td>
                                        <td>
                                            <a href="/Cars/Details/@item.CarId" class="btn btn-sm btn-outline-primary">
                                                <i class="bi bi-eye"></i> View
                                            </a>
                                        </td>
                                    </tr>
                                }
                            </tbody>
                            <tfoot class="table-light">
                                <tr class="fw-bold">
                                    <td colspan="3" class="text-end">Order Total:</td>
                                    <td class="text-end text-primary fs-5">@order.Total.ToString("C")</td>
                                    <td></td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>
            </div>
        }
    }
</div>
'@

# Test Drive My
$testDriveMy = @'
@model List<TestDriveViewModel>

<div class="container py-5">
    <h1 class="mb-4"><i class="bi bi-calendar-check"></i> My Test Drive Appointments</h1>
    
    @if(!Model.Any())
    {
        <div class="alert alert-info">
            <i class="bi bi-info-circle"></i> You haven't scheduled any test drives yet.
            <a href="/Cars" class="alert-link">Browse cars</a> and book a test drive!
        </div>
    }
    else
    {
        <div class="table-responsive">
            <table class="table table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>ID</th>
                        <th>Car</th>
                        <th>Scheduled Date</th>
                        <th>Status</th>
                        <th>Notes</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach(var appt in Model)
                    {
                        <tr>
                            <td><strong>#@appt.Id</strong></td>
                            <td>@appt.CarName</td>
                            <td>@appt.ScheduledAt.ToString("MMM dd, yyyy h:mm tt")</td>
                            <td>
                                @if(appt.Status == "Confirmed")
                                {
                                    <span class="badge bg-success">@appt.Status</span>
                                }
                                else if(appt.Status == "Requested")
                                {
                                    <span class="badge bg-warning text-dark">@appt.Status</span>
                                }
                                else
                                {
                                    <span class="badge bg-secondary">@appt.Status</span>
                                }
                            </td>
                            <td>@(appt.Notes ?? "-")</td>
                        </tr>
                    }
                </tbody>
            </table>
        </div>
    }
</div>
'@

# Account Views
$accountRegister = @'
@model RegisterViewModel

<div class="container py-5">
    <div class="row justify-content-center">
        <div class="col-md-6 col-lg-5">
            <div class="card shadow">
                <div class="card-body p-5">
                    <h2 class="text-center mb-4">Create Account</h2>
                    <form method="post" asp-action="Register">
                        <div class="mb-3">
                            <label asp-for="Email" class="form-label"></label>
                            <input asp-for="Email" class="form-control" />
                            <span asp-validation-for="Email" class="text-danger small"></span>
                        </div>
                        <div class="mb-3">
                            <label asp-for="FullName" class="form-label"></label>
                            <input asp-for="FullName" class="form-control" />
                            <span asp-validation-for="FullName" class="text-danger small"></span>
                        </div>
                        <div class="mb-3">
                            <label asp-for="Password" class="form-label"></label>
                            <input asp-for="Password" class="form-control" />
                            <span asp-validation-for="Password" class="text-danger small"></span>
                        </div>
                        <button class="btn btn-primary w-100 mb-3" type="submit">
                            <i class="bi bi-person-plus"></i> Sign Up
                        </button>
                        <div class="text-center">
                            Already have an account? <a href="/Account/Login">Login here</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
'@

$accountLogin = @'
@model LoginViewModel

<div class="container py-5">
    <div class="row justify-content-center">
        <div class="col-md-6 col-lg-5">
            <div class="card shadow">
                <div class="card-body p-5">
                    <h2 class="text-center mb-4">Welcome Back</h2>
                    <form method="post" asp-action="Login">
                        <div class="mb-3">
                            <label asp-for="Email" class="form-label"></label>
                            <input asp-for="Email" class="form-control" />
                            <span asp-validation-for="Email" class="text-danger small"></span>
                        </div>
                        <div class="mb-3">
                            <label asp-for="Password" class="form-label"></label>
                            <input asp-for="Password" class="form-control" />
                            <span asp-validation-for="Password" class="text-danger small"></span>
                        </div>
                        <button class="btn btn-primary w-100 mb-3" type="submit">
                            <i class="bi bi-box-arrow-in-right"></i> Login
                        </button>
                        <div class="text-center">
                            Don't have an account? <a href="/Account/Register">Sign up</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
'@

$accountDenied = '<div class="container py-5"><div class="row justify-content-center"><div class="col-md-6 text-center"><i class="bi bi-shield-x display-1 text-danger"></i><h1 class="mt-4">Access Denied</h1><p class="lead">You do not have permission to access this resource.</p><a href="/" class="btn btn-primary">Go Home</a></div></div></div>'

$dashboard = '<div class="container py-5"><h1 class="mb-4">Dashboard</h1><div class="row g-4">@if(User.IsInRole("Admin")){<div class="col-md-4"><a href="/Admin/Cars" class="text-decoration-none"><div class="card shadow-sm h-100"><div class="card-body text-center"><i class="bi bi-gear display-4 text-primary"></i><h5 class="mt-3">Manage Cars</h5></div></div></a></div>}@if(User.IsInRole("Staff")||User.IsInRole("Admin")){<div class="col-md-4"><a href="/Staff/Inventory" class="text-decoration-none"><div class="card shadow-sm h-100"><div class="card-body text-center"><i class="bi bi-box-seam display-4 text-success"></i><h5 class="mt-3">Inventory</h5></div></div></a></div><div class="col-md-4"><a href="/Staff/Appointments" class="text-decoration-none"><div class="card shadow-sm h-100"><div class="card-body text-center"><i class="bi bi-calendar2-check display-4 text-info"></i><h5 class="mt-3">Appointments</h5></div></div></a></div>}@if(User.IsInRole("Customer")){<div class="col-md-4"><a href="/Cart" class="text-decoration-none"><div class="card shadow-sm h-100"><div class="card-body text-center"><i class="bi bi-cart display-4 text-warning"></i><h5 class="mt-3">Shopping Cart</h5></div></div></a></div><div class="col-md-4"><a href="/Orders/History" class="text-decoration-none"><div class="card shadow-sm h-100"><div class="card-body text-center"><i class="bi bi-bag-check display-4 text-primary"></i><h5 class="mt-3">My Orders</h5></div></div></a></div><div class="col-md-4"><a href="/TestDrive/My" class="text-decoration-none"><div class="card shadow-sm h-100"><div class="card-body text-center"><i class="bi bi-calendar-check display-4 text-success"></i><h5 class="mt-3">Test Drives</h5></div></div></a></div>}<div class="col-md-4"><a href="/Cars" class="text-decoration-none"><div class="card shadow-sm h-100"><div class="card-body text-center"><i class="bi bi-grid-3x3-gap display-4 text-secondary"></i><h5 class="mt-3">Browse Cars</h5></div></div></a></div></div></div>'

# Write all views
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\Cars\Details.cshtml" -Content $carsDetails
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\Cart\Index.cshtml" -Content $cartIndex
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\Orders\History.cshtml" -Content $ordersHistory
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\TestDrive\My.cshtml" -Content $testDriveMy
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\Account\Register.cshtml" -Content $accountRegister
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\Account\Login.cshtml" -Content $accountLogin
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\Account\AccessDenied.cshtml" -Content $accountDenied
& $WriteTextFunc -Path "$Root\CarShop.Web\Views\Dashboard\Index.cshtml" -Content $dashboard

# Area views in simplified form - just show message to create manually or call another script
& $WriteTextFunc -Path "$Root\CarShop.Web\Areas\Admin\Views\_ViewImports.cshtml" -Content '@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
@using CarShop.Web.ViewModels'
& $WriteTextFunc -Path "$Root\CarShop.Web\Areas\Admin\Views\_ViewStart.cshtml" -Content '@{ Layout = "~/Views/Shared/_Layout.cshtml"; }'
& $WriteTextFunc -Path "$Root\CarShop.Web\Areas\Staff\Views\_ViewImports.cshtml" -Content '@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
@using CarShop.Web.ViewModels'
& $WriteTextFunc -Path "$Root\CarShop.Web\Areas\Staff\Views\_ViewStart.cshtml" -Content '@{ Layout = "~/Views/Shared/_Layout.cshtml"; }'

# Create uploads directory
New-Item -ItemType Directory -Force -Path "$Root\CarShop.Web\wwwroot\uploads" | Out-Null
& $WriteTextFunc -Path "$Root\CarShop.Web\wwwroot\uploads\.gitkeep" -Content ""

Write-Host "  All core views created successfully" -ForegroundColor Green