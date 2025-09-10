# VMware vCenter Password Management Tool
## Version 0.5 BETA - Enterprise Password Management Suite

A professional, DoD-compliant tool for managing passwords across VMware vCenter and ESXi environments with an intuitive Windows Forms GUI interface.

## Quick Start

### **Step 1: Run the Setup Wizard**
```powershell
# Download and run the automated setup wizard
.\VMware-Setup.ps1
```

The setup wizard will:
- Configure your PowerShell environment securely
- Install required VMware management components
- Create configuration templates
- Download the latest application
- Launch the password management tool

**Note**: Initial setup may take several minutes depending on your internet connection.

### **Step 2: Configure and Use**
The application will guide you through:
1. **Configuration**: Add your ESXi hosts and target users
2. **Connection Testing**: Verify vCenter connectivity
3. **Password Operations**: Change passwords safely with dry-run testing

## Features

### **Professional GUI Interface**
- **Password Management Tab**: Main operations with real-time progress tracking
- **Configuration Tab**: Built-in editors for hosts and users
- **GitHub Manager Tab**: Application updates and repository access
- **Logs Tab**: Comprehensive logging with export capabilities

### **Enterprise Security**
- **DoD Compliance**: Government warning banners and audit logging
- **Safe Operations**: Mandatory dry-run testing before live changes
- **Role Separation**: Clear distinction between admin and target users
- **Comprehensive Logging**: All operations tracked and exportable

### **Smart Password Operations**
- **Bulk Operations**: Change passwords across multiple ESXi hosts
- **Progress Tracking**: Real-time status with detailed operation logs
- **Error Handling**: Graceful failure handling with detailed reporting
- **Validation**: Pre-flight checks ensure successful operations

### **User-Friendly Design**
- **Dropdown Menus**: Easy selection of admin and target users
- **Visual Feedback**: Progress bars and status indicators
- **Guided Workflow**: Clear instructions and helpful error messages
- **Self-Updating**: Built-in update mechanism for latest features

## Configuration

### **ESXi Hosts**
Add your ESXi host addresses in the Configuration tab:
```
192.168.1.100
192.168.1.101
esxi-host-01.domain.local
esxi-host-02.domain.local
```

### **User Accounts**
Configure both administrator and target users:
- **Administrator Users**: For vCenter login (administrator, admin)
- **Target Users**: For password changes (root, service accounts)

## System Requirements

- **Windows** with PowerShell 5.1 or later
- **Network Access** to vCenter and ESXi hosts
- **Administrative Privileges** on target systems
- **Internet Access** for initial setup (one-time requirement)

## Typical Workflow

### **Initial Setup**
1. **Run Setup Wizard**: `.\VMware-Setup.ps1` (one-time process)
2. **Configure Hosts**: Add ESXi host addresses
3. **Configure Users**: Add administrator and target user accounts

### **Password Operations**
1. **Select Users**: Choose admin user (vCenter login) and target user (password change)
2. **Test Connection**: Verify vCenter connectivity
3. **Dry Run**: Test password changes safely
4. **Live Operation**: Execute actual password changes
5. **Review Results**: Check operation logs and export if needed

## Security Features

### **DoD Compliance**
- Government system warning banners
- Comprehensive audit logging
- Operation confirmation requirements
- Secure credential handling

### **Safe Operations**
- Mandatory dry-run testing
- Multiple confirmation dialogs
- Detailed operation logging
- Graceful error recovery

### **Enterprise Integration**
- Local component installation (no system-wide changes)
- Portable configuration files
- Comprehensive logging for compliance
- Self-contained operation

## Operation Tracking

The application provides detailed tracking of all operations:
- **Real-time Progress**: Visual progress bars and status updates
- **Detailed Logs**: Timestamped operation logs with success/failure status
- **Export Capability**: Save logs for audit and compliance purposes
- **Error Reporting**: Detailed error messages for troubleshooting

## Updates and Maintenance

### **Automatic Updates**
- Built-in update mechanism through GitHub Manager tab
- Download latest setup wizard and application versions
- No manual file management required

### **Configuration Management**
- Simple text-based configuration files
- Easy backup and restore of settings
- Version control friendly format

## Support

For assistance:
1. **Check Logs**: Review the detailed operation logs in the Logs tab
2. **Export Logs**: Save logs for detailed analysis
3. **Test Connectivity**: Use the built-in connection testing features
4. **Review Configuration**: Verify hosts and users are properly configured

## Security Notice

This tool is designed for authorized personnel only. All operations are logged and monitored. Always use dry-run mode before executing live password changes on production systems.

---

**VMware vCenter Password Management Tool - Version 0.5 BETA**  
*Professional • Secure • User-Friendly • Enterprise Ready*