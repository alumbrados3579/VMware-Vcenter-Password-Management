# VMware vCenter Password Management Tool
## Version 1.0 - Professional DoD-Compliant Password Management

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

### Quick Installation

#### One-Line Installation (Recommended)

**PowerShell (Download and Run):**
```powershell
curl -o VMware-Setup.ps1 https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/VMware-Setup.ps1 && powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
```

**Alternative PowerShell Method:**
```powershell
iwr -Uri "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/VMware-Setup.ps1" -OutFile "VMware-Setup.ps1"; powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
```

**Direct Execution (Advanced Users):**
```powershell
iex (iwr -Uri "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/VMware-Setup.ps1").Content
```

#### Manual Installation

1. Download the setup script:
   ```powershell
   curl -o VMware-Setup.ps1 https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/VMware-Setup.ps1
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
git clone https://github.com/alumbrados3579/VMware-Vcenter-Password-Management.git
cd VMware-Vcenter-Password-Management
powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
```

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
```
Standalone tools for specific tasks with faster startup times.

#### Smart Launcher
```powershell
.\VMware-Password-Manager-Modular.ps1 -Tool CLI
.\VMware-Password-Manager-Modular.ps1 -Tool Config
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

### Performance Benefits

- CLI Workspace: 60-70% faster startup than full GUI
- Configuration Manager: 70% faster startup than full GUI
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

- `Setup-Guide.md` - Installation and configuration procedures
- `CLI-Workspace-Guide.md` - PowerCLI terminal usage and features
- `Configuration-Manager-Guide.md` - Configuration file management
- `Password-Management-Guide.md` - Password operations and security
- `Modular-Architecture-Guide.md` - Architecture overview and best practices

For quick reference, see `HOWTO.txt` in the root directory.

### Installation Troubleshooting

#### Common Issues and Solutions

**Execution Policy Errors:**
```
Problem: "Execution of scripts is disabled on this system"
Solution: Run PowerShell as Administrator and execute:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Download Failures:**
```
Problem: curl or iwr commands fail
Solution: Check internet connectivity and proxy settings
Alternative: Download manually from GitHub releases
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
Solution: Contact IT for GitHub access or download manually
Alternative: Use offline installation method
```

### Version Information

- **Version**: 1.0
- **Release Date**: September 2025
- **Architecture**: Modular with backward compatibility
- **Compliance**: DoD standards with comprehensive audit logging
- **Platform**: Windows PowerShell with VMware PowerCLI

### Author and Development

**Primary Author:** Stace Mitchell <stace.mitchell27@gmail.com>
- Project Creator and Lead Developer
- Architecture Design and Implementation
- DoD Compliance and Security Features

**Development Assistance:** Qodo AI
- Code optimization and best practices
- Documentation enhancement
- Architecture guidance and implementation support

### Support and Maintenance

- All operations logged for compliance and troubleshooting
- Export capabilities for audit reporting
- Modular design for easy maintenance and updates
- Professional interface suitable for enterprise environments

**Contact:**
- Email: stace.mitchell27@gmail.com
- GitHub Issues: [Report Issues](https://github.com/alumbrados3579/VMware-Vcenter-Password-Management/issues)
- Repository: [GitHub Repository](https://github.com/alumbrados3579/VMware-Vcenter-Password-Management)