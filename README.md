# VMware vCenter Password Management Tool
## GUI Edition - Version 2.1 - Local Modules Support

A DoD-compliant tool for managing passwords on VMware vCenter and ESXi environments with a user-friendly Windows Forms GUI interface and local PowerCLI module support.

## 🚀 Quick Start

### **Step 1: Setup PowerShell Environment & Local Modules**
```powershell
# Download and run the setup script
.\VMware-Setup.ps1
```

This will:
- ✅ Set execution policy to RemoteSigned (secure but allows local scripts)
- ✅ Configure PowerShell Gallery and NuGet
- ✅ Download PowerCLI modules to **local Modules directory** (avoids OneDrive issues)
- ✅ Create configuration files (hosts.txt, users.txt)
- ✅ **Never re-download modules if they already exist locally**

### **Step 2: Launch GUI Application**
```powershell
# Launch the GUI password management tool
.\VMware-Password-Manager.ps1
```

## 🖥️ GUI Features

### **Windows Forms Interface**
- ✅ **VMware Management Tab** - vCenter connection, password operations
- ✅ **Configuration Tab** - Edit hosts and users with built-in text editors
- ✅ **Logs Tab** - Real-time application logging with console-style display
- ✅ **Progress Tracking** - Visual progress bars for operations
- ✅ **Status Updates** - Real-time status information

### **VMware Management Tab**
- ✅ vCenter connection testing with visual feedback
- ✅ Password change operations (Dry Run and Live modes)
- ✅ Progress tracking with detailed status updates
- ✅ Connection status indicators

### **Configuration Tab**
- ✅ Built-in text editors for hosts.txt and users.txt
- ✅ Save/Load configuration with one click
- ✅ Syntax highlighting and validation
- ✅ Real-time configuration management

### **Logs Tab**
- ✅ Real-time logging display
- ✅ Console-style interface (black background, green text)
- ✅ Automatic scrolling to latest entries
- ✅ Clear logs functionality

## 📁 File Structure

```
VMware-Vcenter-Password-Management/
├── VMware-Setup.ps1              # PowerShell environment setup with local modules
├── VMware-Password-Manager.ps1   # Main GUI application
├── hosts.txt                     # ESXi hosts configuration
├── users.txt                     # Target users configuration
├── Modules/                      # Local PowerCLI modules (created by setup)
│   └── VMware.PowerCLI/          # Downloaded PowerCLI modules
├── Logs/                         # Application logs
└── README.md                     # This file
```

## 🔧 Key Improvements

### **Local Modules Support**
- ✅ **OneDrive Safe** - Modules stored in local directory, not user profile
- ✅ **No Re-downloads** - Smart detection prevents unnecessary downloads
- ✅ **Network Restriction Friendly** - Works in restricted environments
- ✅ **Version Detection** - Validates module completeness before use

### **Enhanced Module Detection**
- ✅ Checks for PowerCLI manifest files to verify complete installation
- ✅ Only downloads if modules are missing or corrupted
- ✅ Prioritizes local modules over system modules
- ✅ Clear feedback about which modules are being used

### **Security & Compliance**
- ✅ **RemoteSigned Execution Policy** - Secure but allows local scripts
- ✅ DoD warning banners and compliance messaging
- ✅ Comprehensive logging and audit trails
- ✅ Operation confirmation dialogs

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

## 🛡️ Security Features

### **DoD Compliance**
- Government system warning banners
- User acknowledgment requirements
- Comprehensive audit logging
- Operation authorization prompts

### **Safe Operations**
- Dry run mode for all operations
- Password confirmation requirements
- Visual operation confirmations
- Detailed operation logging

## 📖 Usage Examples

### **Basic Password Change with GUI**
1. Run `VMware-Setup.ps1` to configure environment and download modules locally
2. Launch `VMware-Password-Manager.ps1` for GUI interface
3. **VMware Management Tab**: Enter vCenter credentials and test connection
4. **Configuration Tab**: Edit hosts.txt and users.txt as needed
5. **VMware Management Tab**: Enter new password and run Dry Run first
6. Review results in **Logs Tab**, then run Live operation if satisfied

### **Testing Connectivity**
1. Open GUI application
2. Go to **VMware Management Tab**
3. Enter vCenter server, username, and password
4. Click "Test Connection" for immediate feedback
5. View connection status and host count

## 🔄 Module Management

### **Local Modules Priority**
1. **First Priority**: Local `./Modules/VMware.PowerCLI/` directory
2. **Second Priority**: System-wide PowerShell modules
3. **Automatic Detection**: Smart detection prevents re-downloads
4. **OneDrive Safe**: Avoids sync conflicts and file locking issues

### **Setup Process**
- Setup script checks for existing local modules first
- Only downloads if modules are missing or incomplete
- Validates module integrity using manifest files
- Provides clear feedback about module location and version

## 📞 Support

For issues or questions:
1. Check the **Logs Tab** in the GUI for detailed error information
2. Verify local modules: Check `./Modules/VMware.PowerCLI/` directory
3. Test vCenter connectivity using the GUI test function
4. Review configuration files using the built-in editors

## 🔒 Security Notice

This tool is designed for authorized personnel only. All operations are logged and monitored. The GUI interface provides clear visual feedback for all operations and requires explicit confirmation for live changes.

---

**VMware vCenter Password Management Tool - GUI Edition**  
*Local modules support, enhanced security, user-friendly interface*