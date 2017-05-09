using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace AspNetSample.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult About()
        {
            ViewData["Message"] = "This is an ASP.NET app running on .NET Core on Apcera.";

            return View();
        }

        public IActionResult Contact()
        {
            ViewData["Message"] = "Apcera's ASP.NET contact page.";

            return View();
        }

        public IActionResult Error()
        {
            return View();
        }
    }
}
