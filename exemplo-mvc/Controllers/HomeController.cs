using AulaMvc.Models;
using Microsoft.AspNetCore.Mvc;

namespace AulaMvc.Controllers;

public class HomeController(IConfiguration configuration, IWebHostEnvironment environment) : Controller
{
    public IActionResult Index() => View(new BoasVindas(
        configuration["Aluno"] ?? "Minha turma",
        environment.EnvironmentName,
        Request.Scheme));
}
