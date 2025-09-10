# VMware vCenter Password Management Tool
## GUI Edition - Version 2.1 - Local Modules & OneDrive Safe

A DoD-compliant tool for managing passwords on VMware vCenter and ESXi environments with a user-friendly Windows Forms GUI interface and intelligent local PowerCLI module management.

## 🚀 Quick Start Guide

### **Step 1: Initial Setup (One Time)**
```powershell
# Download and run the setup script
.\VMware-Setup.ps1
```

**What this does:**
- ✅ Sets execution policy to `RemoteSigned` (secure but allows local scripts)
- ✅ Configures PowerShell Gallery and NuGet provider
- ✅ Downloads PowerCLI modules to **local `./Modules/` directory** (OneDrive safe!)
- ✅ **Smart detection** - won't re-download if modules already exist
- ✅ Creates configuration files (`hosts.txt`, `users.txt`)

### **Step 2: Launch GUI Application**
```powershell
# Launch the GUI password management tool
.\VMware-Password-Manager.ps1
```

## 🔧 How Local Modules Work

### **OneDrive Safe Installation**
- **Problem**: OneDrive sync conflicts with PowerShell modules in user profile
- **Solution**: Modules installed to `./Modules/` in your working directory
- **Benefit**: No sync conflicts, portable, network-restriction friendly

### **Smart Module Detection**
```
Priority 1: Check if PowerCLI already loaded in memory ✅
Priority 2: Check local ./Modules/ directory ✅  
Priority 3: Check system-wide modules ✅
Priority 4: Download to local directory if needed ✅
```

### **No Re-downloads**
- ✅ Validates existing modules using manifest files
- ✅ Only downloads if missing or corrupted
- ✅ Handles module conflicts gracefully
- ✅ Uses existing loaded modules when available

## 🖥️ GUI Interface Features

### **Three-Tab Interface**

#### **1. VMware Management Tab**
- **vCenter Connection**: Test connectivity with visual feedback
- **Password Operations**: Dry Run and Live modes with progress tracking
- **Status Display**: Real-time connection and operation status
- **Progress Bars**: Visual feedback for long-running operations

#### **2. Configuration Tab**
- **Hosts Editor**: Built-in text editor for `hosts.txt`
- **Users Editor**: Built-in text editor for `users.txt`
- **Save/Load**: One-click configuration management
- **Validation**: Real-time syntax checking

#### **3. Logs Tab**
- **Real-time Logging**: Console-style display (black/green)
- **Auto-scroll**: Always shows latest entries
- **Clear Function**: Reset logs when needed
- **Detailed Tracking**: All operations logged with timestamps

## 📁 Directory Structure

```
VMware-Vcenter-Password-Management/
├── VMware-Setup.ps1              # One-time setup script
├── VMware-Password-Manager.ps1   # Main GUI application
├── hosts.txt                     # ESXi hosts configuration
├── users.txt                     # Target users configuration
├── Modules/                      # Local PowerCLI modules (auto-created)
│   └── VMware.PowerCLI/          # Downloaded PowerCLI modules
├── Logs/                         # Application logs (auto-created)
│   └── vcenter_password_manager_YYYYMMDD.log
└── README.md                     # This documentation
```

## ⚙️ Configuration Files

### **hosts.txt** - ESXi Host Addresses
```bash
# ESXi Hosts Configuration
# Add your ESXi host IP addresses or FQDNs below
# One host per line, comments start with #

# Examples:
192.168.1.100
192.168.1.101
esxi-host-01.domain.local
esxi-host-02.domain.local
```

### **users.txt** - Target Usernames
```bash
# Target Users Configuration  
# Add usernames for password operations
# One username per line, comments start with #

# Common ESXi users:
root
admin
serviceaccount
```

## 🛡️ Security & Compliance

### **DoD Compliance Features**
- ✅ Government system warning banners
- ✅ User acknowledgment requirements
- ✅ Comprehensive audit logging
- ✅ Operation confirmation dialogs
- ✅ Dry run testing before live operations

### **Execution Policy**
- **RemoteSigned**: Allows local scripts, requires signatures for downloaded scripts
- **Better than Bypass**: Maintains security while allowing local development
- **Enterprise Friendly**: Meets most corporate security requirements

## 🔄 Typical Workflow

### **First Time Setup**
1. **Download Scripts**: Copy both `.ps1` files to your working directory
2. **Run Setup**: `.\VMware-Setup.ps1` (downloads modules locally)
3. **Configure**: Edit `hosts.txt` and `users.txt` or use GUI editors
4. **Launch GUI**: `.\VMware-Password-Manager.ps1`

### **Daily Usage**
1. **Launch GUI**: `.\VMware-Password-Manager.ps1` (modules already available)
2. **Test Connection**: VMware Management tab → Test vCenter connection
3. **Dry Run**: Enter new password → Run "Dry Run (Test)" first
4. **Live Operation**: If dry run successful → Run "LIVE Run"
5. **Monitor**: Check Logs tab for detailed operation results

## 🚨 Troubleshooting

### **Module Loading Issues**
**Problem**: "Could not load from local directory, trying system modules..."
**Cause**: PowerCLI modules already loaded in memory from previous session
**Solution**: This is normal! The script detects existing modules and uses them

**Problem**: Warnings about modules "currently in use"
**Cause**: Trying to install over already-loaded modules
**Solution**: Close PowerShell and restart, or the script will use existing modules

### **OneDrive Conflicts**
**Problem**: Module installation fails with sync errors
**Solution**: ✅ Already solved! Modules install to local `./Modules/` directory

### **Network Restrictions**
**Problem**: Cannot download from PowerShell Gallery
**Solution**: 
1. Download modules on unrestricted machine
2. Copy entire `./Modules/` directory to restricted environment
3. Scripts will detect and use local modules

### **Permission Issues**
**Problem**: "Execution policy" errors
**Solution**: Run setup script as administrator or use `-ExecutionPolicy Bypass`

## 📊 Operation Modes

### **Dry Run Mode** (Recommended First)
- ✅ Simulates all operations without making changes
- ✅ Validates connectivity and credentials
- ✅ Shows what would happen in live mode
- ✅ Safe for testing and verification

### **Live Mode** (Production Changes)
- ⚠️ Makes actual password changes on systems
- ⚠️ Requires confirmation dialogs
- ⚠️ All operations logged for audit
- ⚠️ Use only after successful dry run

## 🔍 Module Detection Logic

```powershell
# The script follows this logic:
1. Is PowerCLI already loaded in memory? → Use it ✅
2. Are local modules available in ./Modules/? → Load them ✅
3. Are system modules available? → Load them ✅
4. Nothing found? → Download to ./Modules/ ✅
```

## 📞 Support & Maintenance

### **Log Files**
- Location: `./Logs/vcenter_password_manager_YYYYMMDD.log`
- Format: `[timestamp] [level] message`
- Retention: One file per day, manual cleanup

### **Module Updates**
- Local modules don't auto-update (by design for stability)
- To update: Delete `./Modules/VMware.PowerCLI/` and re-run setup
- Or use PowerShell Gallery: `Update-Module VMware.PowerCLI`

### **Configuration Backup**
- Backup `hosts.txt` and `users.txt` before major changes
- Configuration files are plain text and version-control friendly

## 🎯 Key Benefits

1. **OneDrive Safe**: No more sync conflicts with PowerShell modules
2. **Network Friendly**: Works in restricted environments with local modules
3. **No Re-downloads**: Smart detection prevents unnecessary downloads
4. **GUI Interface**: User-friendly Windows Forms interface
5. **DoD Compliant**: Meets government security requirements
6. **Audit Ready**: Comprehensive logging and operation tracking

---

**VMware vCenter Password Management Tool - GUI Edition**  
*Local modules, enhanced security, OneDrive safe, user-friendly interface*