# VMware vCenter Password Management Tool
## PowerShell Gallery Edition - Version 2.0

A DoD-compliant tool for managing passwords on VMware vCenter and ESXi environments using PowerShell Gallery for module management.

## 🚀 Quick Start

### **Step 1: Setup PowerShell Environment**
```powershell
# Download and run the setup script
.\VMware-Setup.ps1
```

This will:
- Configure PowerShell execution policy
- Install/update NuGet provider
- Install/update PowerShellGet module
- Install/update VMware PowerCLI from PowerShell Gallery
- Create configuration files (hosts.txt, users.txt)

### **Step 2: Configure Your Environment**
Edit the configuration files:
- **hosts.txt** - Add your ESXi host IP addresses or FQDNs
- **users.txt** - Add target usernames for password operations

### **Step 3: Run the Password Manager**
```powershell
# Launch the main application
.\VMware-Password-Manager.ps1
```

## 📋 Features

### **PowerShell Gallery Integration**
- ✅ Automatic PowerCLI installation from PowerShell Gallery
- ✅ Module updates and version management
- ✅ No bundled modules - always uses latest versions
- ✅ Simplified deployment and maintenance

### **Security & Compliance**
- ✅ DoD warning banners and compliance messaging
- ✅ Comprehensive logging and audit trails
- ✅ Dry run mode for testing operations
- ✅ Operation confirmation and authorization prompts

### **Password Management Operations**
- ✅ Test vCenter connections
- ✅ List ESXi users across multiple hosts
- ✅ Change user passwords (individual or bulk)
- ✅ Dry run simulations before live operations
- ✅ Configuration file-based bulk operations

### **User-Friendly Interface**
- ✅ Console-based menu system
- ✅ Clear operation status and progress
- ✅ Detailed logging and error reporting
- ✅ Configuration management interface

## 📁 File Structure

```
VMware-Vcenter-Password-Management/
├── VMware-Setup.ps1              # PowerShell environment setup
├── VMware-Password-Manager.ps1   # Main password management tool
├── hosts.txt                     # ESXi hosts configuration
├── users.txt                     # Target users configuration
├── modules-chunk-*.zip           # PowerCLI module backups (LFS)
├── Logs/                         # Operation logs
└── README.md                     # This file
```

## ⚙️ Configuration

### **hosts.txt**
```
# ESXi Hosts Configuration
# Add your ESXi host IP addresses or FQDNs below
192.168.1.100
192.168.1.101
esxi-host-01.domain.local
esxi-host-02.domain.local
```

### **users.txt**
```
# Target Users Configuration
# Add usernames for password operations
root
admin
serviceaccount
```

## 🔧 Requirements

- **PowerShell 5.1** or later
- **Internet access** for PowerShell Gallery (initial setup)
- **vCenter/ESXi access** with administrative privileges
- **Windows** (for full GUI features) or **PowerShell Core** (console mode)

## 🛡️ Security Features

### **DoD Compliance**
- Government system warning banners
- User acknowledgment requirements
- Comprehensive audit logging
- Operation authorization prompts

### **Safe Operations**
- Dry run mode for all operations
- Confirmation prompts for live changes
- Detailed operation logging
- Error handling and recovery

## 📖 Usage Examples

### **Basic Password Change**
1. Run `VMware-Setup.ps1` to configure environment
2. Edit `hosts.txt` with your ESXi hosts
3. Edit `users.txt` with target usernames
4. Run `VMware-Password-Manager.ps1`
5. Select option 3 for dry run or option 4 for live mode
6. Follow the prompts to complete the operation

### **Testing Connectivity**
1. Run `VMware-Password-Manager.ps1`
2. Select option 1 "Test vCenter Connection"
3. Enter your vCenter credentials
4. Verify connection and host discovery

## 🔄 Updates and Maintenance

The PowerShell Gallery edition automatically:
- Checks for PowerCLI updates during setup
- Uses the latest available module versions
- Provides update notifications
- Maintains compatibility with current VMware environments

## 📞 Support

For issues or questions:
1. Check the `Logs/` directory for detailed error information
2. Verify PowerCLI installation: `Get-Module VMware.PowerCLI -ListAvailable`
3. Test vCenter connectivity before password operations
4. Review configuration files for correct host/user entries

## 🔒 Security Notice

This tool is designed for authorized personnel only. All operations are logged and monitored. Ensure you have proper authorization before performing password changes on production systems.

---

**VMware vCenter Password Management Tool - PowerShell Gallery Edition**  
*Simplified deployment, enhanced security, always up-to-date*