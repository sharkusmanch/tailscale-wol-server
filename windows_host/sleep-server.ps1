# Minimal HTTP API for sleep (bind all, restrict via firewall)
$prefix = "http://+:8765/"

Add-Type -TypeDefinition @"
using System;
using System.Net;
using System.Text;
public class SleepServer {
  public static void Start(string prefix) {
    HttpListener l = new HttpListener();
    l.Prefixes.Add(prefix);
    l.Start();
    for(;;){
      var c = l.GetContext();
      var path = c.Request.RawUrl.ToLowerInvariant();
      if (path == "/sleep") {
        var p = new System.Diagnostics.Process();
        p.StartInfo.FileName = "powershell.exe";
        p.StartInfo.Arguments = "-NoProfile -Command Suspend-Computer -Force";
        p.StartInfo.CreateNoWindow = true;
        p.StartInfo.UseShellExecute = false;
        p.Start();
        var b = Encoding.UTF8.GetBytes("OK\n");
        c.Response.OutputStream.Write(b,0,b.Length);
      } else {
        c.Response.StatusCode = 404;
      }
      c.Response.Close();
    }
  }
}
"@

[SleepServer]::Start($prefix)
