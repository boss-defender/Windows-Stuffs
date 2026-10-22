# Windows ps1 to exe file converter:

<details>
  <summary><b>Quick start (3 Steps only):</b></summary>
  <br>

**Step 1: On Windows, open PowerShell and run:**

```powershell
Install-Module ps2exe -Scope CurrentUser
```
**Keep `<name>.ps1` in same directory where you open powershell**

**Step 3: Set the policy to Bypass or RemoteSigned for just the current process**

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

**Step 3: Then convert your script:**

```powershell
Invoke-ps2exe .\<name>.ps1 .\<name>.exe
```

</details>

---

# Windows exe file Icon change:

**You need a tool name: `Resource Hacker`**

**Link>** https://www.angusj.com/resourcehacker

*Go below for exe program download in the webpage*

**But you can use another tool too**

**You can use any format of image and also ico format, if you use: `Resource Hacker`**

<details>
  <summary><b>How to use:</b></summary>
  <br>
  
> **open Resource hacker**

> **then click on image adder icon .** *You can add any type of image there, but I prefer: ico format.*

> **From file, click on save or save as**

> **If main.exe and new one in the same directory, then `Resource Hacker` may change main.exe to main_original.exe**

> **You will get main.exe with image**

**For image to ico format , visit here:**

https://image.online-convert.com/convert-to-ico

**You can use other image to ico online converter tool too**

---
