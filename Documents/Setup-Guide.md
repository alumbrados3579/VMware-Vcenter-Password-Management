# VMware vCenter Password Management Tool - Setup Guide
## Version 1.0 - Initial Installation and Configuration

### Overview

The VMware-Setup.ps1 script provides automated installation and configuration of the VMware vCenter Password Management Tool. This script handles PowerShell environment setup, PowerCLI installation, and initial configuration file creation.

### Prerequisites

- Windows operating system with PowerShell 5.1 or later
- Internet connection for initial module downloads
- Administrative privileges for PowerShell execution policy changes
- Network access to target vCenter and ESXi environments

### Installation Process

#### Step 1: Download and Execute Setup

```powershell
# Navigate to the tool directory
cd C:\Path\To\VMware-Vcenter-Password-Management

# Execute the setup script
.\VMware-Setup.ps1
```

#### Step 2: Acknowledge DoD Warning

The setup will display a U.S. Government Computer System Warning. Type 'AGREE' to acknowledge and continue with the installation.

#### Step 3: Automated Configuration

The setup script will automatically:

1. **Configure PowerShell Environment**
   - Set execution policy to RemoteSigned for current user
   - Enable TLS 1.2 for secure downloads
   - Configure package management components

2. **Install Package Providers**
   - Install NuGet provider for PowerShell Gallery access
   - Update PowerShellGet module for latest capabilities
   - Handle module conflicts gracefully

3. **Install VMware PowerCLI**
   - Check for existing PowerCLI installations
   - Download PowerCLI to local Modules directory (OneDrive-safe)
   - Configure PowerCLI settings for certificate handling
   - Load and verify PowerCLI functionality

4. **Create Configuration Files**
   - Generate hosts.txt template for ESXi host addresses
   - Generate users.txt template for target user accounts
   - Set up proper file structure for configuration management

5. **Download Main Application**
   - Retrieve latest GUI application from repository
   - Verify successful download and file integrity
   - Prepare application for immediate use

### Configuration Files Created

#### hosts.txt
- **Purpose**: Define ESXi host addresses for password operations
- **Format**: One host per line (IP addresses or fully qualified domain names)
- **Location**: Root directory of the tool
- **Example Content**: Empty file ready for user input

#### users.txt
- **Purpose**: Define target ESXi user accounts for password changes
- **Format**: One username per line
- **Location**: Root directory of the tool
- **Default Content**: Contains 'root' as the default ESXi user

### Local Module Installation

The setup installs PowerCLI modules locally to avoid common issues:

- **OneDrive Sync Conflicts**: Local installation prevents sync issues
- **Version Control**: Maintains specific PowerCLI version compatibility
- **Offline Operation**: Enables operation without internet after initial setup
- **Enterprise Compliance**: Keeps modules within the application directory

### Post-Installation Steps

1. **Configure Host Addresses**
   - Edit hosts.txt to include your ESXi host IP addresses or FQDNs
   - One host per line, no special formatting required

2. **Configure Target Users**
   - Edit users.txt to include ESXi usernames for password operations
   - Common users include: root, admin_swm, admin_kms, service accounts

3. **Test Installation**
   - Launch the main application: `.\VMware-Password-Manager.ps1`
   - Or test individual tools: `.\Tools\CLIWorkspace.ps1`

### Troubleshooting Setup Issues

#### PowerCLI Installation Failures
- **Symptom**: Setup fails during PowerCLI installation
- **Solution**: Check internet connectivity and re-run setup
- **Alternative**: Manually install PowerCLI using PowerShell Gallery

#### Execution Policy Errors
- **Symptom**: Script execution blocked by PowerShell policy
- **Solution**: Run PowerShell as Administrator and execute:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

#### Module Path Issues
- **Symptom**: PowerCLI modules not found after installation
- **Solution**: Restart PowerShell session to refresh module paths
- **Verification**: Check that Modules directory exists in tool folder

#### Network Connectivity Issues
- **Symptom**: Downloads fail or timeout
- **Solution**: Verify internet access and proxy settings
- **Corporate Networks**: May require proxy configuration

### Advanced Setup Options

#### Silent Installation
For automated deployments, the setup can be run with minimal interaction by pre-configuring the environment.

#### Custom Module Paths
The setup automatically creates a local Modules directory, but can be customized for enterprise deployments.

#### Offline Installation
After initial setup, the tool can operate offline using the locally installed modules.

### Security Considerations

- **Local Module Storage**: Modules stored locally for security and compliance
- **Execution Policy**: Set to RemoteSigned for balance of security and functionality
- **Credential Handling**: No credentials stored during setup process
- **Audit Logging**: Setup process logged for compliance tracking

### Maintenance and Updates

- **Re-run Setup**: Execute VMware-Setup.ps1 again to update components
- **Module Updates**: Setup will detect and update PowerCLI modules as needed
- **Configuration Preservation**: Existing hosts.txt and users.txt files are preserved during updates

This setup process ensures a secure, compliant, and fully functional installation of the VMware vCenter Password Management Tool.