# VMware vCenter Password Management Tool - Recreation Prompt
## Complete Development Guide for Professional DoD-Compliant VMware Management Suite

### Overview

This comprehensive prompt will guide you through creating a complete, professional VMware vCenter Password Management Tool with modular architecture, DoD compliance, and enterprise-grade features. Follow this template to recreate the entire tool suite from scratch.

### Master Recreation Prompt

```
Create a comprehensive VMware vCenter Password Management Tool suite with the following specifications:

**PROJECT OVERVIEW:**
Develop a professional, DoD-compliant VMware management tool suite that provides password management, host management, and PowerCLI workspace functionality with both monolithic and modular architectures for optimal performance and usability.

**CORE REQUIREMENTS:**

1. **DoD COMPLIANCE AND SECURITY:**
   - Government-standard warning banners on all applications
   - Comprehensive audit logging with timestamps
   - Secure credential handling (no storage)
   - Professional interface without decorative elements
   - Enterprise-grade security features

2. **MODULAR ARCHITECTURE:**
   - Main monolithic application (full functionality)
   - Individual standalone tools (60-70% faster startup)
   - Shared common library for consistency
   - Smart launcher with multiple access methods
   - Backward compatibility maintained

3. **CORE FUNCTIONALITY MODULES:**
   - Password Management: Change ESXi passwords across multiple hosts
   - Host Management: Create, list, and delete ESXi hosts in vCenter
   - CLI Workspace: Interactive PowerCLI terminal
   - Configuration Manager: Edit hosts.txt and users.txt files
   - Setup Wizard: Automated installation and configuration

**TECHNICAL SPECIFICATIONS:**

**Programming Environment:**
- Platform: Windows PowerShell 5.1+
- Framework: Windows Forms for GUI
- Dependencies: VMware PowerCLI (local installation)
- Architecture: Modular with shared libraries

**File Structure:**
```
VMware-Vcenter-Password-Management/
├── VMware-Setup.ps1                    # Automated setup wizard
├── VMware-Password-Manager.ps1         # Main monolithic application
├── VMware-Password-Manager-Modular.ps1 # Smart launcher
├── VMware-Host-Manager.ps1             # Standalone host manager
├── Tools/                              # Modular components directory
│   ├── Common.ps1                      # Shared utilities library
│   ├── CLIWorkspace.ps1               # Standalone PowerCLI terminal
│   ├── Configuration.ps1              # Standalone config editor
│   └── HostManager.ps1                # Standalone host manager
├── Documents/                          # Comprehensive documentation
│   ├── Setup-Guide.md
│   ├── CLI-Workspace-Guide.md
│   ├── Configuration-Manager-Guide.md
│   ├── Host-Manager-Guide.md
│   ├── Password-Management-Guide.md
│   └── Modular-Architecture-Guide.md
├── Logs/                              # Auto-created for audit logs
├── hosts.txt                          # ESXi host configuration
├── users.txt                          # Target user configuration
├── HOWTO.txt                          # Quick reference guide
├── Installation.txt                   # Installation instructions
├── AUTHORS.txt                        # Author information
└── README.md                          # Project overview
```

**COMPONENT SPECIFICATIONS:**

**1. SETUP WIZARD (VMware-Setup.ps1):**
- Automated PowerShell environment configuration
- Local PowerCLI installation (OneDrive-safe)
- Configuration file template creation
- Post-installation options:
  * Create deployment ZIP for air-gapped networks
  * Launch application immediately
  * Exit for manual execution
- Comprehensive error handling and logging
- Professional status reporting with progress indicators

**2. MAIN APPLICATION (VMware-Password-Manager.ps1):**
- Tabbed interface with multiple functional areas
- Password Management tab with dry-run and live execution
- CLI Workspace tab with interactive PowerCLI terminal
- Configuration tab for hosts.txt and users.txt editing
- GitHub Manager tab for repository operations
- Logs tab with export functionality
- Professional GUI layout with consistent spacing
- Real-time progress monitoring and status updates

**3. MODULAR TOOLS (Tools/ Directory):**

**Common.ps1 - Shared Library:**
- Logging functions with timestamp and level support
- PowerCLI availability testing and loading
- DoD warning banner display
- File operations (hosts, users, logs)
- Standard form creation utilities
- Module path detection and management

**CLIWorkspace.ps1 - PowerCLI Terminal:**
- Interactive PowerCLI command execution
- vCenter connection management
- Command history with UP/DOWN arrow navigation
- Built-in commands (help, clear, exit)
- Real-time command output display
- Professional terminal interface (black/green theme)

**Configuration.ps1 - Config Editor:**
- Dual-pane editor for hosts.txt and users.txt
- Load, save, and validate functionality
- Real-time validation with detailed feedback
- Professional editing interface with large text areas
- Status feedback and error handling

**HostManager.ps1 - Host Operations:**
- Create Host: Add ESXi hosts to vCenter with authentication
- List Hosts: Display all hosts with status and version info
- Delete Host: Safely remove hosts with maintenance mode
- vCenter connection management with status display
- Progress monitoring with visual progress bar
- Real-time status updates with comprehensive logging

**4. SMART LAUNCHER (VMware-Password-Manager-Modular.ps1):**
- Command-line tool selection (-Tool CLI, -Tool Config, -Tool Host)
- Interactive menu with numbered options
- Tool availability listing and help
- Direct tool launching with error handling
- Backward compatibility with full GUI

**GUI DESIGN SPECIFICATIONS:**

**Professional Layout Standards:**
- Consistent 10px spacing between elements
- Professional color scheme (no decorative elements)
- Clear field labeling and logical grouping
- Resizable interfaces with minimum size constraints
- Progress bars and status indicators
- Professional button styling and placement

**Form Components:**
- GroupBox containers for logical sections
- TextBox controls with appropriate sizing
- ComboBox dropdowns for selections
- Button controls with descriptive labels
- Label controls with clear descriptions
- ListBox controls for data display
- ProgressBar controls for operation monitoring

**SECURITY AND COMPLIANCE:**

**DoD Warning Implementation:**
```
*** U.S. GOVERNMENT COMPUTER SYSTEM WARNING ***

You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.
By using this IS (which includes any device attached to this IS), you consent to the following conditions:

- The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, 
  penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), 
  law enforcement (LE), and counterintelligence (CI) investigations.
- At any time, the USG may inspect and seize data stored on this IS.
- Communications using, or data stored on, this IS are not private, are subject to routine monitoring, 
  interception, and search, and may be disclosed or used for any USG-authorized purpose.
- This IS includes security mechanisms to protect USG interests--not for your personal benefit or privacy.

[Tool Name] - DoD Compliant Edition

Click OK to acknowledge and continue...
```

**Audit Logging Requirements:**
- All operations logged with timestamps
- User actions and system responses
- Success and failure tracking
- Exportable log format for compliance
- Daily log file rotation
- Comprehensive error logging

**PERFORMANCE REQUIREMENTS:**

**Startup Time Optimization:**
- Modular tools: 60-70% faster than monolithic
- Lazy loading of non-essential components
- Efficient module path detection
- Minimal dependency loading

**Memory Usage Optimization:**
- Individual tools: 50-80% less memory usage
- Efficient resource management
- Proper cleanup on exit
- Minimal background processes

**INSTALLATION AND DEPLOYMENT:**

**Installation Methods:**
```powershell
# PowerShell (Recommended):
iwr -Uri "https://v12.next.forgejo.org/[repo]/raw/branch/main/VMware-Setup.ps1" -OutFile "VMware-Setup.ps1"; powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1

# Command Prompt:
curl -o VMware-Setup.ps1 https://v12.next.forgejo.org/[repo]/raw/branch/main/VMware-Setup.ps1 & powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1

# Create Directory and Install:
mkdir VMware-Password-Manager; cd VMware-Password-Manager; iwr -Uri "https://v12.next.forgejo.org/[repo]/raw/branch/main/VMware-Setup.ps1" -OutFile "VMware-Setup.ps1"; powershell -ExecutionPolicy Bypass -File VMware-Setup.ps1
```

**Air-Gapped Deployment:**
- ZIP package creation with all dependencies
- Complete offline operation capability
- No internet required after extraction
- Timestamped deployment packages

**USAGE SCENARIOS:**

**Fast Individual Tools (Recommended for Daily Use):**
```powershell
.\Tools\CLIWorkspace.ps1        # PowerCLI Terminal (60-70% faster)
.\Tools\Configuration.ps1       # Config Editor (70% faster)
.\Tools\HostManager.ps1         # Host Manager (70% faster)
```

**Smart Launcher:**
```powershell
.\VMware-Password-Manager-Modular.ps1 -Tool CLI
.\VMware-Password-Manager-Modular.ps1 -Tool Config
.\VMware-Password-Manager-Modular.ps1 -Tool Host
.\VMware-Password-Manager-Modular.ps1 -List
```

**Full GUI Application:**
```powershell
.\VMware-Password-Manager.ps1   # Complete functionality
```

**DOCUMENTATION REQUIREMENTS:**

Create comprehensive documentation including:
- Setup and installation guides
- Individual tool usage guides
- Architecture overview and best practices
- Troubleshooting and FAQ sections
- Security and compliance documentation
- Performance optimization guides

**QUALITY ASSURANCE:**

**Code Quality Standards:**
- Consistent error handling throughout
- Professional commenting and documentation
- Modular design with clear separation of concerns
- Efficient resource management
- Comprehensive input validation

**Testing Requirements:**
- Functional testing of all components
- Performance testing for startup times
- Security testing for DoD compliance
- Integration testing between components
- User acceptance testing for usability

**DELIVERABLES:**

1. Complete source code for all components
2. Comprehensive documentation suite
3. Installation and deployment guides
4. User manuals and quick reference guides
5. Architecture documentation
6. Security and compliance documentation

**SUCCESS CRITERIA:**

- All components function independently and together
- 60-70% performance improvement for modular tools
- DoD compliance requirements met
- Professional interface suitable for enterprise use
- Comprehensive documentation and user guides
- Successful installation and deployment procedures
- Air-gapped deployment capability
- Backward compatibility maintained

Please implement this complete tool suite following these specifications, ensuring professional quality, security compliance, and optimal performance throughout.
```

### Implementation Phases

#### Phase 1: Foundation (Week 1)
1. **Project Structure Setup**
   - Create directory structure
   - Initialize version control
   - Set up development environment

2. **Core Library Development**
   - Implement Common.ps1 shared library
   - Create logging and utility functions
   - Implement DoD warning system

3. **Basic GUI Framework**
   - Create standard form templates
   - Implement consistent styling
   - Set up error handling patterns

#### Phase 2: Core Tools (Week 2-3)
1. **CLI Workspace Development**
   - Interactive PowerCLI terminal
   - Command history implementation
   - Connection management

2. **Configuration Manager**
   - File editing interface
   - Validation systems
   - Save/load functionality

3. **Host Manager**
   - vCenter integration
   - Host CRUD operations
   - Progress monitoring

#### Phase 3: Integration (Week 4)
1. **Main Application Assembly**
   - Tabbed interface creation
   - Component integration
   - Unified functionality

2. **Modular Launcher**
   - Smart tool selection
   - Command-line interface
   - Interactive menu system

3. **Setup Wizard**
   - Automated installation
   - PowerCLI management
   - Configuration creation

#### Phase 4: Documentation and Testing (Week 5)
1. **Comprehensive Documentation**
   - User guides for each component
   - Installation instructions
   - Architecture documentation

2. **Quality Assurance**
   - Functional testing
   - Performance validation
   - Security compliance verification

3. **Deployment Preparation**
   - Installation package creation
   - Air-gapped deployment setup
   - Final integration testing

### Success Metrics

#### Performance Targets
- **Modular Tools**: 60-70% faster startup than monolithic
- **Memory Usage**: 50-80% reduction for individual tools
- **User Experience**: Professional, intuitive interface
- **Reliability**: Comprehensive error handling and recovery

#### Compliance Targets
- **DoD Standards**: Government-compliant warnings and logging
- **Security**: Secure credential handling and audit trails
- **Documentation**: Enterprise-grade documentation suite
- **Deployment**: Multiple installation and deployment options

This comprehensive prompt provides everything needed to recreate the complete VMware vCenter Password Management Tool suite with all its professional features, modular architecture, and enterprise-grade capabilities.