# Windows ps1 to exe file converter:

## Quick start (3 Steps only):

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


