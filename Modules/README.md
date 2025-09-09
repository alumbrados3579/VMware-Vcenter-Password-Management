# VMware PowerCLI Directory
## Local PowerCLI Module Storage

This directory is for storing VMware PowerCLI modules locally with the project.

### 📁 **Expected Structure**

The User Manager will look for PowerCLI in these locations:

#### **Option 1: Direct Manifest (Recommended)**
```
VMware.PowerCLI/
└── VMware.PowerCLI.psd1    # Main PowerCLI manifest file
```

#### **Option 2: Nested Structure**
```
VMware.PowerCLI/
└── VMware.PowerCLI/
    └── VMware.PowerCLI.psd1    # Main PowerCLI manifest file
```

### 🔧 **How to Set Up PowerCLI**

#### **Method 1: Install System-Wide (Easiest)**
```powershell
Install-Module -Name VMware.PowerCLI -Scope CurrentUser
```
*The User Manager will automatically detect and use system-installed PowerCLI.*

#### **Method 2: Copy Local Modules**
1. Download or copy VMware PowerCLI modules
2. Place the `VMware.PowerCLI.psd1` file in one of the expected locations above
3. Ensure all required PowerCLI modules are included

### 🔍 **Debugging PowerCLI Issues**

The User Manager now provides enhanced debugging output:

#### **Console Output Will Show:**
- Root script path being used
- Exact PowerCLI directory path being checked
- Contents of PowerCLI directory (if found)
- All manifest locations being tested
- Detailed error messages if loading fails

#### **If PowerCLI Fails to Load:**
1. **Check console output** - shows exactly where it's looking
2. **Verify file structure** - ensure manifest is in expected location
3. **Check permissions** - ensure PowerShell can read the files
4. **Try system installation** - often easier than local setup

### ✅ **Current Status**

- **Directory Created**: ✅ VMware.PowerCLI directory exists
- **Manifest File**: ❌ Not yet installed
- **System PowerCLI**: ✅ Available as fallback

### 🚀 **Next Steps**

1. **Try launching User Manager** - it will show detailed debugging output
2. **If local PowerCLI needed** - copy modules to this directory
3. **If system PowerCLI preferred** - ensure `Install-Module VMware.PowerCLI` is run

The User Manager will now provide clear feedback about what it finds and where it's looking!