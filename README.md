# VMware vCenter Password Management Tool

## 🚀 DoD Compliant Edition - Version 1.0

A comprehensive, secure, and user-friendly PowerShell GUI application for managing VMware vCenter and ESXi password operations across multiple hosts. Designed specifically for Department of Defense (DoD) environments with enhanced security features, comprehensive logging, and GitHub integration capabilities.

![VMware vCenter Password Management](https://img.shields.io/badge/VMware-vCenter%20Password%20Management-blue)
![DoD Compliant](https://img.shields.io/badge/DoD-Compliant-green)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Windows](https://img.shields.io/badge/Platform-Windows-lightgrey)

## 📋 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Usage](#-usage)
- [Security Features](#-security-features)
- [GitHub Integration](#-github-integration)
- [Documentation](#-documentation)
- [Requirements](#-requirements)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

### 🔐 Core Password Management
- **vCenter Integration**: Connect to VMware vCenter Server for centralized management
- **Bulk Operations**: Change passwords across multiple ESXi hosts simultaneously
- **Dry Run Mode**: Test operations safely before making live changes
- **Live Mode**: Execute real password changes with comprehensive warnings
- **User Query**: Automatically discover and list users across all ESXi hosts
- **Progress Tracking**: Real-time progress bars and detailed operation logs

### 🛡️ Security & Compliance
- **DoD Compliance**: Government warning banners and audit requirements
- **Enhanced Security**: Secure credential handling with automatic memory cleanup
- **Comprehensive Logging**: Verbose logging with credential filtering for audit trails
- **Multi-Level Warnings**: Progressive authorization prompts for live operations
- **Input Validation**: Comprehensive validation and sanitization of all inputs

### 🔧 User Interface
- **Professional GUI**: Modern Windows Forms interface with resizable windows
- **Themed Colors**: Windows-themed color scheme for consistency
- **Multiple Processes**: Separate processes for downloads and management operations
- **Real-Time Logs**: Live operation logs with color-coded status messages
- **Host Management**: Visual host selection and status monitoring

### 🐙 GitHub Integration
- **Repository Management**: Push tools to personal GitHub repositories
- **Selective Upload**: Choose which files to include (Modules.zip excluded)
- **Version Control**: Download latest versions from GitHub repositories
- **Token Authentication**: Secure GitHub Personal Access Token authentication
- **Progress Tracking**: Real-time upload/download progress with status updates

### 📁 Smart Installation
- **One-Click Setup**: Startup script for automated installation
- **Selective Downloads**: Choose full installation or scripts-only updates
- **Local Directory**: No dependency on OneDrive, GPOs, or system installations
- **Module Management**: Optional PowerCLI module download (Modules.zip)
- **Desktop Integration**: Automatic desktop shortcut creation

## 🚀 Quick Start

### Option 1: Automated Installation (Recommended)
```powershell
# Download and run the startup script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/[USERNAME]/VMware-Vcenter-Password-Management/main/Startup-Script.ps1" -OutFile "Startup-Script.ps1"
.\Startup-Script.ps1
```

### Option 2: Manual Installation
1. Download the repository as ZIP
2. Extract to your desired directory
3. Run `VMware-Vcenter-Password-Management.ps1`

### Option 3: Git Clone
```bash
git clone https://github.com/[USERNAME]/VMware-Vcenter-Password-Management.git
cd VMware-Vcenter-Password-Management
powershell -ExecutionPolicy Bypass -File VMware-Vcenter-Password-Management.ps1
```

## 📦 Installation

### Prerequisites
- **PowerShell**: 5.1 or later
- **Operating System**: Windows 10/11 or Windows Server 2016+
- **VMware PowerCLI**: 12.0+ (can be installed automatically)
- **Network Access**: Internet connectivity for GitHub operations
- **Permissions**: Local user permissions (no admin rights required)

### Automated Installation Process

The startup script provides three installation options:

#### 1. Full Installation (Recommended)
- Downloads all scripts and documentation
- Includes Modules.zip with PowerCLI modules
- Creates complete offline-capable environment
- Perfect for first-time installations

#### 2. Scripts and Documentation Only
- Downloads scripts, tools, and documentation
- Does NOT include Modules.zip
- Use for updates when PowerCLI is already installed
- Faster download and smaller footprint

#### 3. Custom Installation
- Choose specific components to download
- Selective file inclusion
- Advanced users and specific requirements

### Manual Configuration

After installation, configure these files:

#### hosts.txt
```
# ESXi Hosts Configuration
192.168.1.100
192.168.1.101
esxi-host-01.domain.local
esxi-host-02.domain.local
```

#### users.txt (Optional)
```
# Target Users Configuration
root
admin
serviceaccount
```

## 🎯 Usage

### Main Interface

The application provides two main tabs:

#### 1. VMware Management Tab
- **vCenter Connection**: Enter vCenter server details
- **Operation Mode**: Choose between Dry Run and Live Mode
- **Target User Configuration**: Specify users and passwords
- **Host Selection**: View and select ESXi hosts
- **Operation Logs**: Real-time status and progress

#### 2. GitHub Manager Tab
- **Credentials**: GitHub Personal Access Token authentication
- **Repository Operations**: Push to and download from GitHub
- **File Selection**: Choose which files to include/exclude
- **Progress Tracking**: Upload/download progress monitoring

### Workflow Examples

#### Password Change Operation
1. **Connect to vCenter**
   - Enter vCenter address (IP or FQDN)
   - Provide vCenter credentials
   - Test connection to verify access

2. **Configure Target**
   - Specify target username
   - Enter current password
   - Set new password and confirm

3. **Select Hosts**
   - Review discovered ESXi hosts
   - Select hosts for password change
   - Verify host connectivity

4. **Execute Operation**
   - Start with Dry Run mode for testing
   - Review simulation results
   - Switch to Live Mode for actual changes
   - Monitor progress and results

#### GitHub Operations
1. **Authenticate**
   - Enter GitHub Personal Access Token
   - Validate token and retrieve username
   - Confirm repository access

2. **Upload to GitHub**
   - Select files to include
   - Exclude Modules.zip as specified
   - Monitor upload progress
   - Verify successful completion

3. **Download Updates**
   - Fetch latest version from repository
   - Update scripts and documentation
   - Preserve local configurations
   - Verify update completion

## 🔒 Security Features

### DoD Compliance
- **Government Warning Banners**: Required DoD system access warnings
- **Audit Logging**: Comprehensive operation logging for compliance
- **Authorization Prompts**: Multi-level confirmation for sensitive operations
- **Secure Credential Handling**: Automatic memory cleanup and secure storage

### Enhanced Security Measures
- **Input Validation**: Comprehensive validation of all user inputs
- **Credential Filtering**: Logs exclude sensitive credential information
- **Secure Communications**: HTTPS for all GitHub operations
- **Error Handling**: Graceful error handling with security considerations

### Operational Security
- **Dry Run Mode**: Safe testing environment before live operations
- **Progressive Warnings**: Escalating warnings for live operations
- **Operation Isolation**: Separate processes for different operations
- **Audit Trail**: Complete audit trail of all operations and decisions

## 🐙 GitHub Integration

### Repository Management
- **Personal Repositories**: Push tools to your own GitHub repositories
- **Selective Upload**: Choose specific files to include or exclude
- **Version Control**: Maintain version history and change tracking
- **Collaborative Development**: Share tools with team members

### File Management
- **Automatic Exclusion**: Modules.zip automatically excluded from uploads
- **Selective Inclusion**: Choose scripts, documentation, and tools
- **Update Management**: Download only updated files during version updates
- **Configuration Preservation**: Local configurations maintained during updates

### Authentication & Security
- **Personal Access Tokens**: Secure GitHub authentication
- **Token Validation**: Automatic token verification and user identification
- **Secure Storage**: Tokens handled securely without persistent storage
- **Repository Verification**: Automatic repository access verification

## 📚 Documentation

### Quick Reference
- **README.md**: This comprehensive overview
- **GETTING-STARTED.md**: Step-by-step getting started guide
- **SECURITY.md**: Detailed security features and compliance information

### Detailed Documentation
- **Documentation/Security/**: Security implementation details
- **Documentation/Workflows/**: Detailed workflow documentation
- **Documentation/Troubleshooting/**: Common issues and solutions

### API Documentation
- **PowerCLI Integration**: VMware PowerCLI usage and best practices
- **GitHub API**: GitHub integration implementation details
- **Logging System**: Comprehensive logging system documentation

## 💻 Requirements

### System Requirements
- **Operating System**: Windows 10/11, Windows Server 2016+
- **PowerShell**: Version 5.1 or later
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Storage**: 500MB free space (1GB for full installation)
- **Network**: Internet connectivity for GitHub operations

### Software Dependencies
- **VMware PowerCLI**: 12.0 or later (auto-installed if needed)
- **.NET Framework**: 4.7.2 or later (typically pre-installed)
- **Windows Forms**: Included with Windows

### Network Requirements
- **vCenter Access**: Network connectivity to VMware vCenter Server
- **ESXi Access**: Network connectivity to ESXi hosts (typically through vCenter)
- **GitHub Access**: HTTPS connectivity to github.com (for GitHub features)
- **PowerShell Gallery**: Access for PowerCLI module downloads (if needed)

### Permissions
- **Local User**: Standard user permissions sufficient
- **No Admin Rights**: Administrative privileges not required
- **File System**: Write access to installation directory
- **Network**: Standard network access permissions

## 🔧 Troubleshooting

### Common Issues

#### Connection Problems
**Issue**: Cannot connect to vCenter Server
**Solutions**:
- Verify vCenter server address and credentials
- Check network connectivity and firewall settings
- Ensure vCenter management interface is accessible
- Verify SSL certificate settings

#### PowerCLI Issues
**Issue**: PowerCLI module not found or outdated
**Solutions**:
- Run full installation to download PowerCLI modules
- Install PowerCLI manually: `Install-Module VMware.PowerCLI`
- Update PowerCLI: `Update-Module VMware.PowerCLI`
- Check PowerShell execution policy

#### GitHub Authentication
**Issue**: GitHub token validation fails
**Solutions**:
- Verify Personal Access Token is correct and active
- Check token permissions (repo access required)
- Ensure internet connectivity to github.com
- Regenerate token if necessary

#### Permission Errors
**Issue**: Access denied or permission errors
**Solutions**:
- Run from directory with write permissions
- Check file and folder permissions
- Avoid system directories (use user directories)
- Verify antivirus software isn't blocking operations

### Diagnostic Steps

1. **Check Prerequisites**
   - Verify PowerShell version: `$PSVersionTable.PSVersion`
   - Test internet connectivity: `Test-Connection github.com`
   - Check available disk space
   - Verify write permissions in installation directory

2. **Validate Configuration**
   - Review hosts.txt for correct ESXi addresses
   - Verify users.txt contains valid usernames
   - Check vCenter connectivity and credentials
   - Test PowerCLI module availability

3. **Review Logs**
   - Check application logs in Logs/ directory
   - Review startup script logs for installation issues
   - Examine PowerCLI error messages
   - Analyze GitHub operation logs

### Getting Help

1. **Documentation**: Review comprehensive documentation in Documentation/ folder
2. **Logs**: Check detailed logs for specific error messages
3. **GitHub Issues**: Report issues on the GitHub repository
4. **Community**: Engage with the VMware PowerCLI community

## 🤝 Contributing

We welcome contributions to improve the VMware vCenter Password Management Tool!

### How to Contribute

1. **Fork the Repository**
   ```bash
   git clone https://github.com/[USERNAME]/VMware-Vcenter-Password-Management.git
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow PowerShell best practices
   - Maintain DoD compliance requirements
   - Add appropriate logging and error handling
   - Update documentation as needed

4. **Test Thoroughly**
   - Test in both Dry Run and Live modes
   - Verify GitHub integration functionality
   - Test on different Windows versions
   - Validate security features

5. **Submit Pull Request**
   - Provide clear description of changes
   - Include testing results
   - Reference any related issues

### Development Guidelines

- **Security First**: Maintain DoD compliance and security standards
- **Comprehensive Logging**: Add appropriate logging for all operations
- **Error Handling**: Implement robust error handling and recovery
- **Documentation**: Update documentation for any new features
- **Testing**: Thoroughly test all changes before submission

### Code Standards

- **PowerShell Style**: Follow PowerShell best practices and style guidelines
- **Security**: Implement secure coding practices
- **Comments**: Provide clear comments for complex logic
- **Functions**: Create reusable functions with clear parameters
- **Error Handling**: Implement comprehensive error handling

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Third-Party Components

- **VMware PowerCLI**: VMware, Inc. - [License](https://www.vmware.com/support/developer/PowerCLI/)
- **Windows Forms**: Microsoft Corporation - Part of .NET Framework

## 🏷️ Version History

### Version 1.0 (Current)
- Initial release with full GUI interface
- vCenter and ESXi password management
- GitHub integration capabilities
- DoD compliance features
- Comprehensive logging and security
- Automated installation system

### Planned Features
- **Multi-vCenter Support**: Manage multiple vCenter servers
- **Scheduled Operations**: Automated password rotation
- **Advanced Reporting**: Enhanced reporting and analytics
- **Role-Based Access**: User role and permission management
- **API Integration**: REST API for automation integration

## 📞 Support

### Documentation
- **Getting Started**: See Documentation/GETTING-STARTED.md
- **Security Guide**: See Documentation/Security/SECURITY.md
- **Troubleshooting**: See Documentation/TROUBLESHOOTING.md

### Community Support
- **GitHub Issues**: Report bugs and request features
- **Discussions**: Join community discussions
- **Wiki**: Access community-maintained documentation

### Professional Support
For enterprise support and custom development, contact the development team through the GitHub repository.

---

## 🎯 Quick Links

- **[Download Latest Release](https://github.com/[USERNAME]/VMware-Vcenter-Password-Management/releases/latest)**
- **[Getting Started Guide](Documentation/GETTING-STARTED.md)**
- **[Security Documentation](Documentation/Security/SECURITY.md)**
- **[Troubleshooting Guide](Documentation/TROUBLESHOOTING.md)**
- **[Contributing Guidelines](CONTRIBUTING.md)**
- **[License Information](LICENSE)**

---

**VMware vCenter Password Management Tool** - Secure, compliant, and efficient VMware infrastructure management for DoD environments.

*Developed with security, compliance, and usability in mind.*