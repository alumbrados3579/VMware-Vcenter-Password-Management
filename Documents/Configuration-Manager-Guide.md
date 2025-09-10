# VMware vCenter Password Management Tool - Configuration Manager Guide
## Version 1.0 - Hosts and Users Configuration Editor

### Overview

The Configuration Manager is a standalone tool for managing the hosts.txt and users.txt configuration files used by the VMware vCenter Password Management Tool. This tool provides a user-friendly interface for editing, validating, and maintaining configuration data.

### Key Features

- **Fast Startup**: 70% faster than the full GUI application
- **Dual Configuration Management**: Edit both hosts and users in one interface
- **Real-time Validation**: Validate configurations before saving
- **Professional Editor**: Large text areas with proper formatting
- **Status Feedback**: Clear indication of operation success or failure
- **File Management**: Load, save, and validate configuration files

### Launching the Configuration Manager

#### Direct Launch (Fastest)
```powershell
.\Tools\Configuration.ps1
```

#### Via Modular Launcher
```powershell
.\VMware-Password-Manager-Modular.ps1 -Tool Config
```

#### Via Interactive Menu
```powershell
.\VMware-Password-Manager-Modular.ps1
# Select option 2 for Configuration Manager
```

### Interface Components

#### ESXi Hosts Configuration Section
- **Text Editor**: Large multi-line text area for host addresses
- **Save Hosts Button**: Save current content to hosts.txt
- **Load Hosts Button**: Load existing hosts.txt file
- **Validate Hosts Button**: Verify host address formats

#### Target Users Configuration Section
- **Text Editor**: Large multi-line text area for usernames
- **Save Users Button**: Save current content to users.txt
- **Load Users Button**: Load existing users.txt file
- **Validate Users Button**: Verify username formats

#### Status Display
- **Status Label**: Shows current operation status and results
- **Color Coding**: Green for success, red for errors, orange for warnings

### Configuration File Management

#### Hosts Configuration (hosts.txt)

**Purpose**: Define ESXi host addresses for password management operations

**Format Requirements**:
- One host per line
- IP addresses (e.g., 192.168.1.100)
- Fully qualified domain names (e.g., esxi-host-01.domain.local)
- No special formatting or delimiters required

**Example Content**:
```
192.168.1.100
192.168.1.101
192.168.1.102
esxi-host-01.domain.local
esxi-host-02.domain.local
esxi-lab-01.test.local
```

**Validation Rules**:
- Valid IPv4 addresses (xxx.xxx.xxx.xxx format)
- Valid domain names (alphanumeric with dots and hyphens)
- No empty lines or invalid characters
- Maximum 255 characters per line

#### Users Configuration (users.txt)

**Purpose**: Define target ESXi user accounts for password change operations

**Format Requirements**:
- One username per line
- Standard ESXi username formats
- No domain qualifiers (ESXi local accounts only)

**Example Content**:
```
root
admin_swm
admin_kms
admin
serviceaccount
backup_user
```

**Validation Rules**:
- Alphanumeric characters, underscores, and hyphens allowed
- Maximum 64 characters per username
- No spaces or special characters
- Case-sensitive usernames

### Using the Configuration Manager

#### Loading Existing Configurations

1. **Load Hosts Configuration**
   - Click "Load Hosts" button
   - Existing hosts.txt content appears in the editor
   - If file doesn't exist, editor remains empty

2. **Load Users Configuration**
   - Click "Load Users" button
   - Existing users.txt content appears in the editor
   - If file doesn't exist, default "root" user is loaded

#### Editing Configurations

1. **Edit Host Addresses**
   - Type or paste host addresses in the hosts text area
   - One host per line
   - Use IP addresses or fully qualified domain names
   - Remove any unwanted entries

2. **Edit User Accounts**
   - Type or paste usernames in the users text area
   - One username per line
   - Use ESXi local account names only
   - Add or remove users as needed

#### Validating Configurations

1. **Validate Hosts**
   - Click "Validate Hosts" button
   - System checks each host address format
   - Results displayed in popup dialog and status area
   - Shows count of valid vs. potentially invalid hosts

2. **Validate Users**
   - Click "Validate Users" button
   - System checks each username format
   - Results displayed in popup dialog and status area
   - Shows count of valid vs. potentially invalid users

#### Saving Configurations

1. **Save Hosts**
   - Click "Save Hosts" button
   - Content saved to hosts.txt in root directory
   - Success confirmation displayed
   - File created if it doesn't exist

2. **Save Users**
   - Click "Save Users" button
   - Content saved to users.txt in root directory
   - Success confirmation displayed
   - File created if it doesn't exist

### Advanced Features

#### Validation Details

**Host Validation Checks**:
- IPv4 address format validation
- Domain name format validation
- Character limit enforcement
- Duplicate detection
- Empty line removal

**User Validation Checks**:
- Username character validation
- Length limit enforcement
- Special character detection
- Duplicate detection
- Case sensitivity verification

#### Error Handling

**File Operation Errors**:
- Permission denied errors
- File not found conditions
- Disk space issues
- Network drive problems

**Validation Errors**:
- Invalid format detection
- Character encoding issues
- Line ending problems
- Content corruption detection

#### Status Feedback

**Color-Coded Status**:
- **Green**: Successful operations
- **Red**: Error conditions
- **Orange**: Warning conditions
- **Blue**: Informational messages

**Detailed Messages**:
- Operation completion confirmations
- Error descriptions with solutions
- Validation results with counts
- File location information

### Best Practices

#### Configuration Management

**Host Configuration**:
- Use fully qualified domain names when possible
- Group hosts by environment (production, test, development)
- Maintain consistent naming conventions
- Document host purposes in separate documentation

**User Configuration**:
- Include only necessary user accounts
- Use descriptive account names when possible
- Coordinate with ESXi administrators for account management
- Maintain separate lists for different environments

#### File Management

**Backup Procedures**:
- Backup configuration files before major changes
- Maintain version control for configuration changes
- Document configuration change reasons
- Test configurations in non-production environments

**Security Considerations**:
- Protect configuration files from unauthorized access
- Use secure file storage locations
- Audit configuration changes regularly
- Coordinate with security teams for compliance

#### Workflow Integration

**With Password Management**:
- Validate configurations before password operations
- Ensure host accessibility before adding to configuration
- Verify user account existence on target hosts
- Test connectivity after configuration changes

**With CLI Workspace**:
- Use validated host lists for PowerCLI operations
- Coordinate user account management across tools
- Maintain consistent configuration across all tools
- Document operational procedures

### Troubleshooting

#### File Access Issues
- **Problem**: Cannot save configuration files
- **Solution**: Check file permissions and disk space
- **Prevention**: Run with appropriate user privileges

#### Validation Failures
- **Problem**: Valid entries marked as invalid
- **Solution**: Check for hidden characters or formatting issues
- **Resolution**: Re-type entries manually to ensure clean format

#### Loading Problems
- **Problem**: Configuration files not loading
- **Solution**: Verify file existence and format
- **Recovery**: Create new configuration files if corrupted

#### Performance Issues
- **Problem**: Slow validation or saving
- **Solution**: Check for very large configuration files
- **Optimization**: Break large configurations into smaller files

### Integration with Main Application

The Configuration Manager integrates seamlessly with the main VMware vCenter Password Management Tool:

- **Shared Files**: Uses the same hosts.txt and users.txt files
- **Real-time Updates**: Changes immediately available to other tools
- **Consistent Validation**: Same validation rules across all components
- **Unified Logging**: Operations logged in main application log files

This tool provides essential configuration management capabilities while maintaining the fast, focused approach of the modular architecture.