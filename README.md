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

### Quick Start

#### Initial Setup

1. Run the automated setup wizard:
   ```powershell
   .\VMware-Setup.ps1
   ```

2. Configure your environment:
   - Edit `hosts.txt` with your ESXi host addresses
   - Edit `users.txt` with target user accounts

3. Launch the application:
   ```powershell
   .\VMware-Password-Manager.ps1
   ```

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

### Version Information

- **Version**: 1.0
- **Release Date**: September 2025
- **Architecture**: Modular with backward compatibility
- **Compliance**: DoD standards with comprehensive audit logging
- **Platform**: Windows PowerShell with VMware PowerCLI

### Support and Maintenance

- All operations logged for compliance and troubleshooting
- Export capabilities for audit reporting
- Modular design for easy maintenance and updates
- Professional interface suitable for enterprise environments