# VMware vCenter Password Management Tool
## Version 1.0 - Professional DoD-Compliant Password Management

🔒 **SECURE REPOSITORY** - Now hosted on Forgejo for enhanced security and privacy

### 🛡️ Repository Security Notice

This project has migrated to **Forgejo** for enhanced security:
- **Primary Repository:** https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management
- **Security Features:** No AI training, no tracking, open source platform
- **Privacy Protection:** European-style privacy standards
- **File Integrity:** All code verified with SHA-256 and MD5 checksums

### Overview

A professional, DoD-compliant solution for managing passwords across VMware vCenter and ESXi environments. This tool provides both a comprehensive GUI interface and fast standalone components for specific tasks.

### Key Features

- DoD compliance with government warning banners and audit logging
- Safe operations with mandatory dry-run testing before live changes
- Role separation between admin and target users
- Comprehensive logging with export capabilities
- Modular architecture for fast individual tool usage
- Interactive PowerCLI workspace for advanced users
- Professional interface without decorative elements
- Enterprise-grade security and audit capabilities

### 🔐 Secure Installation

#### One-Line Installation (Recommended)

**PowerShell (Recommended):**
```powershell
iwr -Uri "https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management/raw/branch/main/VMware-Setup.ps1" -OutFile "VMware-Setup.ps1"; powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
```

**Command Prompt (cmd):**
```cmd
curl -o VMware-Setup.ps1 https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management/raw/branch/main/VMware-Setup.ps1 & powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
```

**Create Directory and Install:**
```powershell
mkdir VMware-Password-Manager; cd VMware-Password-Manager; iwr -Uri "https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management/raw/branch/main/VMware-Setup.ps1" -OutFile "VMware-Setup.ps1"; powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
```

**Direct Execution (Advanced Users):**
```powershell
iex (iwr -Uri "https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management/raw/branch/main/VMware-Setup.ps1").Content
```

#### Manual Installation

1. Download the setup script:
   ```powershell
   iwr -Uri "https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management/raw/branch/main/VMware-Setup.ps1" -OutFile "VMware-Setup.ps1"
   ```

2. Run the automated setup wizard:
   ```powershell
   powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
   ```

3. Configure your environment:
   - Edit `hosts.txt` with your ESXi host addresses
   - Edit `users.txt` with target user accounts

4. Launch the application:
   ```powershell
   .\VMware-Password-Manager.ps1
   ```

#### Alternative: Full Repository

```bash
git clone https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management.git
cd VMware-Vcenter-Password-Management
powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
```

### 🔍 File Integrity Verification

This repository includes a comprehensive file integrity verification system:

```powershell
# Verify all critical files
.\Verify-FileIntegrity.ps1 -Action Verify

# Generate new checksums
.\Verify-FileIntegrity.ps1 -Action Generate

# Full verification and generation
.\Verify-FileIntegrity.ps1 -Action Both
```

**Security Features:**
- **Dual-hash verification** using SHA-256 and MD5
- **12 critical files** monitored for unauthorized changes
- **Tamper detection** and alerting
- **Professional security reporting**
- **Air-gapped deployment** support

### What the Setup Script Does

The automated setup script will:

1. **Configure PowerShell Environment** - Set secure execution policies and enable TLS 1.2
2. **Install VMware PowerCLI** - Download PowerCLI modules to local directory (OneDrive-safe)
3. **Create Configuration Files** - Generate hosts.txt and users.txt templates
4. **Download Application Components** - Get the latest GUI and modular tools
5. **Verify Installation** - Test components and offer post-installation options:
   - Create ZIP package for air-gapped/classified networks
   - Launch the application immediately
   - Exit setup to run tools manually

**Benefits of Local Installation:**
- No administrator privileges required
- Prevents OneDrive sync conflicts
- Portable installation in working directory
- Enterprise-compliant local module storage
- Optional ZIP packaging for air-gapped networks
- Complete offline deployment capability

### Usage Options

#### Full GUI Application
```powershell
.\VMware-Password-Manager.ps1
```
Complete functionality with all features in a tabbed interface.

#### Fast Individual Tools
```powershell
.\Tools\CLIWorkspace.ps1        # PowerCLI Terminal (60-70% faster)
.\Tools\Configuration.ps1       # Config Editor (70% faster)
.\Tools\HostManager.ps1         # Host Manager (70% faster)
```
Standalone tools for specific tasks with faster startup times.

**Smart Launcher:**
```powershell
.\VMware-Password-Manager-Modular.ps1 -Tool CLI
.\VMware-Password-Manager-Modular.ps1 -Tool Config
.\VMware-Password-Manager-Modular.ps1 -Tool Host
.\VMware-Password-Manager-Modular.ps1 -List
```
Flexible launcher with command-line options and interactive menu.

### Security and Compliance

- Government-standard DoD compliance warnings
- Comprehensive audit logging for all operations
- Mandatory dry-run testing before live password changes
- Secure credential handling with no storage
- Role-based access separation
- Professional interface suitable for government and enterprise environments
- **File integrity verification** system with dual-hash protection
- **Secure repository hosting** on privacy-focused platform

### Performance Benefits

- CLI Workspace: 60-70% faster startup than full GUI
- Configuration Manager: 70% faster startup than full GUI
- Host Manager: 70% faster startup than full GUI
- Reduced memory usage: 50-80% less for individual tools
- Modular architecture allows focused tool usage

### System Requirements

- Windows with PowerShell 5.1 or later
- Network access to vCenter and ESXi hosts
- Administrative privileges on target systems
- Internet access for initial setup (one-time requirement)
- Minimum 4GB RAM recommended
- 500MB free disk space for modules and logs

### Documentation

Comprehensive documentation is available in the `Documents/` directory:

**User Guides:**
- `Setup-Guide.md` - Installation and configuration procedures
- `CLI-Workspace-Guide.md` - PowerCLI terminal usage and features
- `Configuration-Manager-Guide.md` - Configuration file management
- `Host-Manager-Guide.md` - ESXi host management operations
- `Password-Management-Guide.md` - Password operations and security
- `Modular-Architecture-Guide.md` - Architecture overview and best practices

**Development Templates:**
- `Pseudocode-Prompt-Template.md` - Algorithm design and pseudocode generation
- `Workflow-Flowchart-Prompt-Template.md` - Process visualization and flowcharts
- `VMware-Tool-Recreation-Prompt.md` - Complete tool recreation guide

**Quick Access:**
- `Documents/README.md` - Complete documentation index and navigation guide
- `HOWTO.txt` - Quick reference guide in root directory
- `Installation.txt` - Installation instructions and troubleshooting

### Installation Troubleshooting

#### Common Issues and Solutions

**Execution Policy Errors:**
```
Problem: "Execution of scripts is disabled on this system"
Solution: Run PowerShell as regular user and execute:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Download Failures:**
```
Problem: curl or iwr commands fail
Solution: Check internet connectivity and proxy settings
Alternative: Download manually from Forgejo repository
```

**PowerCLI Installation Issues:**
```
Problem: PowerCLI installation fails during setup
Solution: Re-run setup script, check internet connectivity
Manual: Install-Module VMware.PowerCLI -Scope CurrentUser
```

**Corporate Network Issues:**
```
Problem: Downloads blocked by corporate firewall
Solution: Contact IT for Forgejo access or download manually
Alternative: Use offline installation method
```

### 🔒 Security Recommendations

1. **Repository Security:**
   - Use the Forgejo repository for enhanced privacy
   - Verify file integrity before deployment
   - Enable signed commits for additional security

2. **File Integrity Monitoring:**
   - Run `.\Verify-FileIntegrity.ps1` before each deployment
   - Store checksums in a secure location
   - Verify integrity after any collaboration

3. **Air-Gapped Deployment:**
   - Use the ZIP package feature for secure networks
   - Verify checksums before deployment
   - Maintain offline backup of verified code

### Version Information

- **Version**: 1.0
- **Release Date**: September 2025
- **Architecture**: Modular with backward compatibility
- **Compliance**: DoD standards with comprehensive audit logging
- **Platform**: Windows PowerShell with VMware PowerCLI
- **Security**: Enhanced with file integrity verification and secure hosting

### Author and Development

**Primary Author:** Stace Mitchell <stace.mitchell27@gmail.com>
- Project Creator and Lead Developer
- Architecture Design and Implementation
- DoD Compliance and Security Features

**Development Assistance:** Qodo AI
- Code optimization and best practices
- Documentation enhancement
- Architecture guidance and implementation support
- Security enhancement and file integrity systems

### Support and Maintenance

- All operations logged for compliance and troubleshooting
- Export capabilities for audit reporting
- Modular design for easy maintenance and updates
- Professional interface suitable for enterprise environments
- File integrity verification for secure deployments

**Contact:**
- Email: stace.mitchell27@gmail.com
- Forgejo Issues: [Report Issues](https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management/issues)
- Primary Repository: [Forgejo Repository](https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management)

### 🛡️ Migration from GitHub

This project has been migrated from GitHub to Forgejo for enhanced security:
- **Reason**: Unauthorized modifications detected on GitHub
- **Solution**: Secure hosting on privacy-focused Forgejo platform
- **Verification**: All files verified with integrity checking system
- **Benefits**: No AI training, no tracking, enhanced privacy protection