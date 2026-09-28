using System.Net;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllersWithViews();
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.ForwardLimit = 1;
    if (IPAddress.TryParse(builder.Configuration["TrustedProxy"], out var proxy))
    {
        options.KnownProxies.Add(proxy);
        options.KnownProxies.Add(proxy.MapToIPv6());
    }
});

var app = builder.Build();
app.UseForwardedHeaders();
// Neste laboratório, o Nginx faz o redirecionamento HTTP -> HTTPS.
app.UseRouting();
app.MapControllerRoute("default", "{controller=Home}/{action=Index}/{id?}");
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));
app.Run();
