# VMware vCenter Password Management Tool
## Version 0.5 BETA - GUI Edition

A DoD-compliant tool for managing passwords on VMware vCenter and ESXi environments with an intuitive Windows Forms GUI interface.

## 🚀 Quick Start

### **Step 1: Run Setup**
```powershell
# Download and run the setup script - it does everything for you
.\VMware-Setup.ps1
```

### **Step 2: Use the Tool**
The setup script will automatically:
- ✅ Configure your PowerShell environment
- ✅ Download required VMware modules locally
- ✅ Create configuration files
- ✅ Launch the GUI application

## 🖥️ GUI Interface

### **Three Simple Tabs**
- **VMware Management** - Connect to vCenter and manage passwords
- **Configuration** - Edit your hosts and users
- **Logs** - Monitor operations in real-time

### **Key Features**
- ✅ **Test Connection** - Verify vCenter connectivity before operations
- ✅ **Dry Run Mode** - Test password changes safely before going live
- ✅ **Live Mode** - Execute actual password changes
- ✅ **Progress Tracking** - Visual feedback for all operations
- ✅ **Real-time Logging** - Monitor everything that happens

## ⚙️ Configuration

### **Hosts Configuration**
Add your ESXi host addresses in the Configuration tab:
```
192.168.1.100
192.168.1.101
esxi-host-01.domain.local
```

### **Users Configuration**
Add target usernames for password operations:
```
root
admin
serviceaccount
```

## 🛡️ Security & Compliance

- ✅ **DoD Compliant** - Government warning banners and audit logging
- ✅ **Safe Operations** - Dry run testing before live changes
- ✅ **Comprehensive Logging** - All operations tracked and logged
- ✅ **Confirmation Dialogs** - Multiple confirmations for live operations

## 📋 Typical Workflow

1. **Run Setup**: `.\VMware-Setup.ps1` (one time setup)
2. **Configure**: Add your ESXi hosts and target users
3. **Test Connection**: Verify vCenter connectivity
4. **Dry Run**: Test password changes safely
5. **Live Operation**: Execute actual password changes
6. **Monitor**: Review logs for operation results

## 🔧 Requirements

- **Windows** with PowerShell 5.1 or later
- **Network access** to vCenter and ESXi hosts
- **Administrative privileges** on target systems
- **Internet access** for initial module download (one time)

## 📞 Support

- Check the **Logs tab** for detailed operation information
- All operations are logged to `./Logs/` directory
- Configuration files are stored as `hosts.txt` and `users.txt`

## 🔒 Security Notice

This tool is designed for authorized personnel only. All operations are logged and monitored. Use dry run mode before executing live password changes on production systems.

---

**VMware vCenter Password Management Tool - Version 0.5 BETA**  
*Simple setup, powerful features, enterprise ready*