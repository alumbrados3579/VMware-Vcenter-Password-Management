# 🚀 Getting Started with VMware vCenter Password Management Tool

## 📋 Quick Start Guide

Welcome to the VMware vCenter Password Management Tool - DoD Compliant Edition! This guide will help you get up and running quickly with secure password management for your VMware infrastructure.

## 🎯 What You'll Learn

- How to install the tool using the automated startup script
- How to configure vCenter connections
- How to perform password changes safely
- How to use GitHub integration features
- Best practices for secure operations

## 📦 Installation Options

### Option 1: One-Click Installation (Recommended)

The easiest way to get started is with our automated startup script:

```powershell
# Download and run the startup script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/[USERNAME]/VMware-Vcenter-Password-Management/main/Startup-Script.ps1" -OutFile "Startup-Script.ps1"
.\Startup-Script.ps1
```

**What this does:**
- Downloads all necessary files to your chosen directory
- Creates proper folder structure
- Optionally downloads PowerCLI modules (Modules.zip)
- Creates desktop shortcut for easy access
- Sets up configuration files

### Option 2: Manual Download

If you prefer manual installation:

1. Download the repository as ZIP from GitHub
2. Extract to your desired directory (e.g., `C:\Users\[Username]\VMware-Tools`)
3. Run `VMware-Vcenter-Password-Management.ps1`

### Option 3: Git Clone

For developers or advanced users:

```bash
git clone https://github.com/[USERNAME]/VMware-Vcenter-Password-Management.git
cd VMware-Vcenter-Password-Management
powershell -ExecutionPolicy Bypass -File VMware-Vcenter-Password-Management.ps1
```

## 🔧 Initial Setup

### Step 1: Choose Installation Type

When you run the startup script, you'll see three options:

#### Full Installation (Recommended for first-time users)
- ✅ All scripts and documentation
- ✅ PowerCLI modules (Modules.zip) for offline use
- ✅ Complete offline capability
- ✅ Desktop shortcut creation

#### Scripts and Documentation Only (For updates)
- ✅ All scripts and documentation
- ❌ No Modules.zip (assumes PowerCLI already installed)
- ✅ Faster download
- ✅ Smaller footprint

#### Custom Installation (Advanced users)
- ✅ Choose specific components
- ✅ Selective file inclusion
- ✅ Tailored to specific needs

### Step 2: Choose Installation Directory

**Recommended locations:**
- `C:\Users\[Username]\VMware-Tools` (Default)
- `C:\Tools\VMware-vCenter-Management`
- Any directory where you have write permissions

**Avoid these locations:**
- System directories (C:\Windows, C:\Program Files)
- OneDrive synchronized folders (for security)
- Network drives (for performance)

### Step 3: Complete Installation

The installer will:
1. Create directory structure
2. Download selected components
3. Create configuration files
4. Set up desktop shortcut (if Windows)
5. Display completion summary

## ⚙️ Configuration

### Configure ESXi Hosts

Edit the `hosts.txt` file in your installation directory:

```
# ESXi Hosts Configuration
# Add your ESXi host IP addresses or FQDNs below
# One host per line, comments start with #

# Production ESXi Hosts
192.168.1.100
192.168.1.101
192.168.1.102

# Development ESXi Hosts
esxi-dev-01.domain.local
esxi-dev-02.domain.local

# Lab Environment
10.0.1.50
10.0.1.51
```

### Configure Target Users (Optional)

Edit the `users.txt` file for common target users:

```
# Target Users Configuration
# Add usernames that can be targeted for password changes
# One username per line, comments start with #

# Standard ESXi Users
root
admin
serviceaccount
backup_user

# Custom Users
vmware_admin
monitoring_user
```

## 🖥️ First Launch

### Starting the Application

**Option 1: Desktop Shortcut**
- Double-click the "VMware vCenter Password Management" shortcut

**Option 2: Manual Launch**
```powershell
cd "C:\Users\[Username]\VMware-Tools\VMware-Vcenter-Password-Management"
.\VMware-Vcenter-Password-Management.ps1
```

**Option 3: PowerShell Direct**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Path\To\VMware-Vcenter-Password-Management.ps1"
```

### DoD Warning Banner

Upon launch, you'll see the DoD compliance warning banner:

```
*** U.S. GOVERNMENT COMPUTER SYSTEM WARNING ***

You are accessing a U.S. Government (USG) Information System (IS) 
that is provided for USG-authorized use only...

[Full DoD warning text]

Click 'OK' to indicate your understanding and acceptance of these terms.
```

**Important:** This warning is required for DoD compliance. Click 'OK' to proceed.

## 🎮 Using the Main Interface

### VMware Management Tab

This is your primary workspace for password management operations.

#### 1. vCenter Connection Section

**vCenter Address:** Enter your vCenter server IP or FQDN
- Examples: `192.168.1.10`, `vcenter.domain.local`

**vCenter Username:** Your vCenter administrator account
- Examples: `administrator@vsphere.local`, `domain\admin`

**vCenter Password:** Your vCenter password
- Securely masked input field

**Test Connection Button:** Verify connectivity before operations
- ✅ Success: Displays connected ESXi hosts
- ❌ Failure: Shows error message and troubleshooting tips

#### 2. Operation Mode Section

**Dry Run/Simulation (Default):**
- ✅ Safe testing mode
- ✅ No actual changes made
- ✅ Shows what would happen
- ✅ Perfect for training and validation

**Live Mode:**
- ⚠️ Makes real changes to production systems
- ⚠️ Requires additional confirmation
- ⚠️ All actions are logged and audited
- ⚠️ Use only after successful dry run testing

#### 3. Target User Configuration

**Target Username:** The user account to change
- Can type manually or use users.txt file
- Examples: `root`, `admin`, `serviceaccount`

**Use users.txt file:** Checkbox to enable file-based user selection
- When checked, grays out manual username entry
- Reads from users.txt file in installation directory

**Current Password:** The existing password for the target user
- Required for authentication
- Securely masked input

**New Password:** The new password to set
- Must meet your organization's password policy
- Securely masked input

**Confirm Password:** Confirmation of new password
- Must match new password exactly
- Prevents typos in password entry

#### 4. ESXi Hosts and Operation Logs

**ESXi Hosts List:**
- Populated after successful vCenter connection
- Shows host name, connection state, and power state
- Multi-select capability (Ctrl+click, Shift+click)
- All hosts selected by default

**Operation Logs:**
- Real-time status updates
- Color-coded messages (Green=Success, Red=Error, Yellow=Warning)
- Scrollable history of all operations
- Automatically saved to log files

**Progress Bar:**
- Shows completion percentage during operations
- Updates in real-time
- Helps estimate remaining time

#### 5. Action Buttons

**Query ESXi Users:**
- Discovers all user accounts across selected hosts
- Populates users.txt file automatically
- Useful for discovering existing accounts

**Execute Dry Run:**
- Performs simulation of password change
- Shows what would happen without making changes
- Safe for testing and validation

**Execute LIVE Mode:**
- Performs actual password changes
- Requires operation mode to be set to "Live Mode"
- Shows additional security warnings

**Clear Logs:**
- Clears the operation logs display
- Does not affect saved log files
- Useful for starting fresh operations

### GitHub Manager Tab

Manage your tool deployment and updates through GitHub integration.

#### 1. GitHub Credentials Section

**Personal Access Token:**
- GitHub Personal Access Token for authentication
- Securely masked input field
- Required for all GitHub operations

**GitHub Username:**
- Automatically populated after token validation
- Read-only field showing authenticated user

**Validate Token Button:**
- Verifies token authenticity
- Retrieves and displays username
- Enables repository operations

#### 2. Repository Operations

**Push to GitHub:**
- Uploads selected files to your GitHub repository
- Automatically excludes Modules.zip as requested
- Shows upload progress and status

**Download Latest:**
- Downloads latest version from GitHub repository
- Updates scripts and documentation only
- Preserves local configuration files

#### 3. File Selection

**Files to Include:**
- Checklist of files to upload to GitHub
- Modules.zip automatically excluded
- Can select/deselect individual files
- Default selection includes all scripts and documentation

## 🔄 Common Workflows

### Workflow 1: First-Time Password Change

1. **Launch Application**
   - Use desktop shortcut or manual launch
   - Acknowledge DoD warning banner

2. **Connect to vCenter**
   - Enter vCenter server address
   - Provide administrator credentials
   - Click "Test Connection"
   - Verify ESXi hosts are discovered

3. **Configure Operation**
   - Keep "Dry Run/Simulation" selected
   - Enter target username (e.g., "root")
   - Enter current password
   - Enter and confirm new password

4. **Select Hosts**
   - Review discovered ESXi hosts
   - Select hosts for password change (all selected by default)

5. **Execute Dry Run**
   - Click "Execute Dry Run"
   - Review simulation results in logs
   - Verify operation would succeed

6. **Execute Live Operation**
   - Switch to "Live Mode"
   - Acknowledge security warnings
   - Click "Execute LIVE Mode"
   - Monitor progress and results

### Workflow 2: Bulk User Discovery

1. **Connect to vCenter**
   - Establish vCenter connection as above

2. **Query Users**
   - Click "Query ESXi Users"
   - Wait for discovery to complete
   - Review found users in logs

3. **Review users.txt**
   - Open users.txt file in installation directory
   - Review discovered user accounts
   - Edit file to include only target users

4. **Use File-Based Selection**
   - Check "Use users.txt file" checkbox
   - Target username field will be grayed out
   - Operations will use users from file

### Workflow 3: GitHub Integration

1. **Prepare GitHub Repository**
   - Create new repository on GitHub
   - Generate Personal Access Token with repo permissions

2. **Authenticate**
   - Switch to "GitHub Manager" tab
   - Enter Personal Access Token
   - Click "Validate Token"
   - Verify username is displayed

3. **Upload Tools**
   - Review file selection list
   - Ensure Modules.zip is not selected
   - Click "Push to GitHub"
   - Monitor upload progress

4. **Download Updates**
   - Click "Download Latest"
   - Wait for download to complete
   - Review updated files

## 🛡️ Security Best Practices

### Operational Security

1. **Always Start with Dry Run**
   - Never skip simulation mode
   - Verify all operations before going live
   - Use dry run for training and validation

2. **Verify Connections**
   - Always test vCenter connectivity first
   - Ensure all target hosts are reachable
   - Validate credentials before operations

3. **Monitor Operations**
   - Watch operation logs in real-time
   - Verify success/failure for each host
   - Review log files after operations

4. **Secure Credentials**
   - Never save passwords in plain text
   - Use secure password managers
   - Change default passwords immediately

### File Security

1. **Installation Directory**
   - Use directories with appropriate permissions
   - Avoid shared or network locations
   - Protect configuration files

2. **Log Files**
   - Review log files regularly
   - Archive old logs securely
   - Ensure logs don't contain sensitive data

3. **GitHub Operations**
   - Use Personal Access Tokens, not passwords
   - Limit token permissions to necessary scopes
   - Regularly rotate access tokens

## 🔍 Troubleshooting Quick Fixes

### Connection Issues

**Problem:** Cannot connect to vCenter
**Quick Fixes:**
- Verify vCenter address is correct
- Check network connectivity: `ping vcenter-address`
- Ensure credentials are correct
- Check firewall settings

**Problem:** ESXi hosts not discovered
**Quick Fixes:**
- Verify vCenter manages the ESXi hosts
- Check ESXi host connectivity from vCenter
- Ensure ESXi hosts are powered on
- Verify ESXi management network settings

### Authentication Issues

**Problem:** GitHub token validation fails
**Quick Fixes:**
- Verify token is copied correctly (no extra spaces)
- Check token hasn't expired
- Ensure token has 'repo' permissions
- Try regenerating the token

**Problem:** ESXi authentication fails
**Quick Fixes:**
- Verify username and password are correct
- Check if account is locked
- Ensure account has sufficient privileges
- Try connecting directly to ESXi host

### Application Issues

**Problem:** GUI doesn't load
**Quick Fixes:**
- Ensure running on Windows with .NET Framework
- Check PowerShell execution policy
- Verify Windows Forms are available
- Try running as different user

**Problem:** PowerCLI errors
**Quick Fixes:**
- Install PowerCLI: `Install-Module VMware.PowerCLI`
- Update PowerCLI: `Update-Module VMware.PowerCLI`
- Import module manually: `Import-Module VMware.PowerCLI`
- Check PowerShell Gallery connectivity

## 📞 Getting Help

### Documentation Resources
- **README.md**: Comprehensive overview and features
- **Documentation/Security/**: Security implementation details
- **Documentation/Troubleshooting/**: Detailed troubleshooting guide

### Log Files
- **Application Logs**: `Logs/vcenter_password_manager_[date].log`
- **Startup Logs**: `startup_[timestamp].log`
- **PowerCLI Logs**: Check PowerCLI module logs

### Community Support
- **GitHub Issues**: Report bugs and request features
- **GitHub Discussions**: Community Q&A and tips
- **VMware Community**: PowerCLI specific questions

### Professional Support
For enterprise support, custom development, or training, contact the development team through the GitHub repository.

## 🎯 Next Steps

Now that you're up and running:

1. **Practice with Dry Run**: Get comfortable with the interface using simulation mode
2. **Configure Your Environment**: Set up hosts.txt and users.txt for your infrastructure
3. **Establish Procedures**: Create standard operating procedures for your team
4. **Set Up GitHub Integration**: Enable version control and collaboration
5. **Train Your Team**: Share knowledge and best practices with colleagues

## 🏆 Success Tips

- **Start Small**: Begin with a few test hosts before scaling up
- **Document Everything**: Keep records of all password changes
- **Regular Testing**: Periodically test the tool with dry runs
- **Stay Updated**: Regularly download updates from GitHub
- **Security First**: Always follow DoD security procedures

---

**Congratulations!** You're now ready to securely manage VMware passwords with the DoD-compliant VMware vCenter Password Management Tool.

For additional help, refer to the comprehensive documentation in the Documentation/ folder or visit the GitHub repository for community support.