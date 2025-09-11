# Dual Repository Strategy - GitHub & Forgejo
## Version 1.0 - Comprehensive Repository Management

### 🎯 **STRATEGY OVERVIEW**

This document outlines the dual repository strategy for maintaining both GitHub and Forgejo repositories while providing automated management capabilities.

### 🏠 **REPOSITORY LOCATIONS**

#### **Primary Repository (Secure)**
- **Platform:** Forgejo v12
- **URL:** https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management
- **Purpose:** Primary development, secure hosting, privacy-focused
- **Features:** No AI training, community-controlled, enhanced privacy

#### **Secondary Repository (Public)**
- **Platform:** GitHub
- **URL:** https://github.com/alumbrados3579/VMware-Vcenter-Password-Management
- **Purpose:** Public visibility, testing, automated agent commands
- **Features:** Redirects to Forgejo for downloads, maintains visibility

### 🔄 **REPOSITORY SYNCHRONIZATION**

#### **Content Strategy:**
1. **Forgejo (Primary):** Contains latest, secure versions
2. **GitHub (Secondary):** Contains debadged versions pointing to Forgejo
3. **Automated Sync:** Agent system manages updates between repositories

#### **Version Differences:**
- **Forgejo:** Full-featured versions with all capabilities
- **GitHub:** Debadged versions with DoD warnings removed
- **Setup Scripts:** GitHub version points to Forgejo for downloads

### 🤖 **AUTOMATED AGENT SYSTEM**

#### **Agent Components:**
1. **VMware-Agent.ps1** - Main agent script
2. **DoDify.ps1** - DoD compliance management
3. **Scheduled Task** - 15-minute monitoring interval
4. **.test File** - Command interface for remote operations

#### **Agent Installation:**
```powershell
# Install agent (requires admin privileges)
.\VMware-Agent.ps1 -Install

# Check agent status
.\VMware-Agent.ps1 -Status

# Test agent once
.\VMware-Agent.ps1 -RunOnce

# Uninstall agent
.\VMware-Agent.ps1 -Uninstall
```

#### **Supported Commands:**
```
UPDATE-REPO GITHUB              # Update from GitHub
UPDATE-REPO FORGEJO             # Update from Forgejo
DOWNLOAD-FILE <url> <path>      # Download file
RUN-SCRIPT <path>               # Execute PowerShell script
DODIFY <script|ALL>             # Add DoD warnings
DEBADGE <script|ALL>            # Remove DoD warnings
GIT-COMMIT <message>            # Git commit with message
GIT-PUSH <remote>               # Git push to remote
POWERSHELL <command>            # Execute PowerShell command
```

### 🛡️ **SECURITY FEATURES**

#### **DoD Compliance Management:**
- **DoDify.ps1** adds/removes DoD warnings as needed
- **Automated compliance** for government environments
- **Backup creation** before modifications
- **Version tracking** for compliance auditing

#### **Repository Security:**
- **Forgejo:** Enhanced privacy, no AI training
- **GitHub:** Public visibility with secure download redirection
- **Agent Monitoring:** Automated security updates
- **File Integrity:** Verification systems in place

### 📁 **FILE STRUCTURE**

```
VMware-Vcenter-Password-Management/
├── VMware-Setup.ps1                    # Main setup (points to Forgejo)
├── VMware-Setup-Debadged.ps1          # Debadged version
├── VMware-Password-Manager.ps1         # Main application
├── VMware-Password-Manager-Modular.ps1 # Modular launcher
├── VMware-Host-Manager.ps1             # Host manager
├── VMware-Agent.ps1                    # Automated agent
├── DoDify.ps1                          # DoD compliance tool
├── Tools/                              # Modular tools
│   ├── Common.ps1
│   ├── CLIWorkspace.ps1
│   ├── Configuration.ps1
│   └── HostManager.ps1
├── Documents/                          # Documentation
├── .test                               # Agent command file
└── README.md                           # Repository documentation
```

### 🔧 **DEPLOYMENT SCENARIOS**

#### **Scenario 1: Standard Enterprise**
```powershell
# Download from GitHub (redirects to Forgejo)
iwr -Uri "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/VMware-Setup.ps1" -OutFile "VMware-Setup.ps1"
powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
```

#### **Scenario 2: DoD/Government Environment**
```powershell
# Download and DoDify
iwr -Uri "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/VMware-Setup.ps1" -OutFile "VMware-Setup.ps1"
.\DoDify.ps1 -TargetScript VMware-Setup.ps1
powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
```

#### **Scenario 3: Air-Gapped Network**
```powershell
# Use ZIP package with all components
# Created by setup script with offline capability
```

### 🔄 **MAINTENANCE WORKFLOWS**

#### **Daily Operations:**
1. **Agent monitors** .test file every 15 minutes
2. **Automatic updates** applied based on commands
3. **Repository sync** maintained automatically
4. **Logging** of all operations for audit

#### **Manual Operations:**
```powershell
# Update GitHub setup to point to Forgejo
cp VMware-Setup-Debadged.ps1 VMware-Setup.ps1
git add VMware-Setup.ps1
git commit -m "update: Point setup to secure Forgejo repository"
git push origin main

# Add DoD compliance to all scripts
.\DoDify.ps1 -AllScripts

# Remove DoD compliance from all scripts
.\DoDify.ps1 -AllScripts -RemoveWarnings
```

### 📊 **MONITORING & LOGGING**

#### **Agent Logging:**
- **File:** VMware-Agent.log
- **Format:** [timestamp] [level] message
- **Levels:** INFO, SUCCESS, WARNING, ERROR, COMMAND
- **Rotation:** Manual cleanup required

#### **Status Monitoring:**
```powershell
# Check agent status
.\VMware-Agent.ps1 -Status

# View recent log entries
Get-Content VMware-Agent.log -Tail 20

# Monitor real-time
Get-Content VMware-Agent.log -Wait
```

### 🎯 **REMOTE COMMAND EXAMPLES**

#### **Example .test File Content:**
```
# Update repository and add DoD compliance
UPDATE-REPO FORGEJO
DODIFY ALL
GIT-COMMIT "agent: Add DoD compliance to all scripts"
GIT-PUSH origin

# Download and deploy new component
DOWNLOAD-FILE https://example.com/new-tool.ps1 Tools/NewTool.ps1
GIT-COMMIT "agent: Add new tool component"
GIT-PUSH forgejo

# Execute maintenance script
POWERSHELL Get-ChildItem *.log | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item
GIT-COMMIT "agent: Clean old log files"
```

### 🔒 **SECURITY CONSIDERATIONS**

#### **Agent Security:**
- **Limited scope** - only executes predefined commands
- **Logging** of all operations for audit trail
- **Error handling** prevents system damage
- **User context** - runs under current user privileges

#### **Repository Security:**
- **Forgejo primary** - enhanced privacy and security
- **GitHub secondary** - public visibility with secure redirects
- **File integrity** verification systems
- **Automated monitoring** for unauthorized changes

### 📈 **BENEFITS**

#### **For Users:**
- **Seamless experience** - downloads automatically secure
- **Choice of compliance** - DoD or standard versions
- **Enhanced privacy** - primary hosting on Forgejo
- **Maintained compatibility** - GitHub still accessible

#### **For Administrators:**
- **Automated management** - agent handles routine tasks
- **Dual repository** - redundancy and flexibility
- **Compliance tools** - easy DoD certification
- **Remote control** - manage via .test file commands

#### **For Security:**
- **Privacy protection** - no AI training on Forgejo
- **Audit trails** - comprehensive logging
- **Integrity verification** - file checksums
- **Controlled access** - agent-based automation

### 🚀 **GETTING STARTED**

#### **Quick Setup:**
1. **Clone repository** from either GitHub or Forgejo
2. **Install agent** for automated management
3. **Configure compliance** as needed (DoD or standard)
4. **Test remote commands** via .test file

#### **For Remote Management:**
1. **Create .test file** in repository root
2. **Add commands** using supported syntax
3. **Commit and push** to trigger agent
4. **Monitor logs** for execution results

This dual repository strategy provides maximum flexibility while maintaining security and enabling automated management for enterprise VMware environments.