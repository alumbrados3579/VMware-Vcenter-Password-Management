# VMware vCenter Password Management Tool - CLI Workspace Guide
## Version 1.0 - Interactive PowerCLI Terminal

### Overview

The CLI Workspace is a standalone PowerCLI terminal that provides direct access to VMware vCenter and ESXi environments. This tool offers the fastest startup time and is optimized for power users who primarily work with PowerCLI commands.

### Key Features

- **Fast Startup**: 60-70% faster than the full GUI application
- **Interactive Terminal**: Real-time command execution with immediate feedback
- **Command History**: Navigate previous commands using UP/DOWN arrow keys
- **Built-in Help**: Integrated help system for PowerCLI commands
- **Connection Management**: Independent vCenter connection handling
- **Professional Interface**: Terminal-style interface with syntax highlighting

### Launching the CLI Workspace

#### Direct Launch (Fastest)
```powershell
.\Tools\CLIWorkspace.ps1
```

#### Via Modular Launcher
```powershell
.\VMware-Password-Manager-Modular.ps1 -Tool CLI
```

#### Via Interactive Menu
```powershell
.\VMware-Password-Manager-Modular.ps1
# Select option 1 for CLI Workspace
```

### Interface Components

#### Connection Section
- **vCenter Server**: Enter the vCenter server address or FQDN
- **Username**: vCenter administrator username (default: administrator@vsphere.local)
- **Password**: vCenter administrator password
- **Connect Button**: Establish connection to vCenter
- **Disconnect Button**: Terminate vCenter connection
- **Status Display**: Shows current connection status

#### Command Interface
- **Command Input**: Text field for entering PowerCLI commands
- **Execute Button**: Manual command execution (or press ENTER)
- **Clear Button**: Clear the output terminal
- **Output Terminal**: Black background terminal with green text for command results

### Using the CLI Workspace

#### Establishing Connection

1. **Enter Connection Details**
   - vCenter Server: vcenter.domain.local
   - Username: administrator@vsphere.local
   - Password: [your vCenter password]

2. **Connect to vCenter**
   - Click "Connect" button or use PowerCLI connect command
   - Wait for connection confirmation
   - Status will show "Connected to [server name]"

#### Executing Commands

1. **Direct Command Entry**
   - Type PowerCLI commands in the command input field
   - Press ENTER to execute immediately
   - Results appear in the output terminal

2. **Command Examples**
   ```powershell
   Get-VMHost
   Get-VM | Select Name, PowerState
   Get-Datastore | Sort FreeSpaceGB
   Get-Cluster
   Get-VirtualSwitch
   ```

#### Built-in Commands

- **help**: Display CLI workspace help and common commands
- **clear**: Clear the output terminal
- **exit**: Close the CLI workspace application

#### Command History

- **UP Arrow**: Navigate to previous commands
- **DOWN Arrow**: Navigate to next commands
- **History Limit**: Stores last 50 commands per session

### Advanced Features

#### Terminal Capabilities

- **Syntax Highlighting**: Green text on black background for readability
- **Scrolling Output**: Automatic scrolling to show latest results
- **Copy/Paste Support**: Standard Windows clipboard operations
- **Font Optimization**: Consolas font for clear command display

#### Connection Management

- **Multiple Connections**: Support for multiple vCenter connections
- **Session Persistence**: Maintains connection throughout session
- **Automatic Cleanup**: Proper disconnection on application exit
- **Error Handling**: Graceful handling of connection failures

#### Performance Optimization

- **Fast Loading**: Minimal startup time compared to full GUI
- **Memory Efficient**: Lower memory footprint for focused usage
- **Responsive Interface**: Immediate command execution feedback
- **Background Processing**: Non-blocking command execution

### Common Use Cases

#### Daily Administration Tasks
```powershell
# Check ESXi host status
Get-VMHost | Select Name, ConnectionState, PowerState

# Monitor VM performance
Get-VM | Get-Stat -Stat cpu.usage.average -Realtime

# Review datastore capacity
Get-Datastore | Select Name, CapacityGB, FreeSpaceGB
```

#### Troubleshooting Operations
```powershell
# Check for VM issues
Get-VM | Where {$_.PowerState -eq "PoweredOff"}

# Review host hardware status
Get-VMHost | Get-View | Select Name, Hardware

# Monitor network configuration
Get-VirtualSwitch | Select Name, NumPorts
```

#### Reporting and Analysis
```powershell
# Generate VM inventory report
Get-VM | Select Name, PowerState, NumCpu, MemoryGB | Export-Csv vm_report.csv

# Check cluster resource usage
Get-Cluster | Select Name, DrsEnabled, HAEnabled

# Review snapshot usage
Get-VM | Get-Snapshot | Select VM, Name, Created, SizeGB
```

### Troubleshooting

#### Connection Issues
- **Problem**: Cannot connect to vCenter
- **Solution**: Verify server address, credentials, and network connectivity
- **Check**: Ensure vCenter services are running and accessible

#### Command Execution Errors
- **Problem**: PowerCLI commands fail
- **Solution**: Verify connection status and command syntax
- **Reference**: Use Get-Help [command] for syntax assistance

#### Performance Issues
- **Problem**: Slow command execution
- **Solution**: Check network latency and vCenter performance
- **Optimization**: Use specific filters to reduce data retrieval

#### Module Loading Issues
- **Problem**: PowerCLI commands not recognized
- **Solution**: Restart CLI workspace to reload modules
- **Verification**: Run Get-Module to check loaded modules

### Best Practices

#### Security
- **Credential Management**: Use secure credential storage methods
- **Session Timeout**: Disconnect when not actively using
- **Audit Logging**: All commands logged for compliance tracking

#### Performance
- **Targeted Queries**: Use filters to limit data retrieval
- **Batch Operations**: Group related commands for efficiency
- **Resource Monitoring**: Monitor vCenter load during operations

#### Workflow Optimization
- **Command Templates**: Save frequently used commands
- **Script Integration**: Combine with PowerShell scripts for automation
- **Result Processing**: Use PowerShell pipeline for data manipulation

### Integration with Other Tools

#### Full GUI Application
- **Seamless Transition**: Switch to full GUI for complex operations
- **Shared Configuration**: Uses same hosts.txt and users.txt files
- **Consistent Logging**: Integrated with main application logging

#### Configuration Manager
- **Host Management**: Use Configuration tool to manage host lists
- **User Management**: Configure target users for password operations
- **Validation**: Verify configurations before CLI operations

#### Automation Scripts
- **PowerShell Integration**: Embed CLI commands in larger scripts
- **Batch Processing**: Process multiple hosts or operations
- **Scheduled Tasks**: Integrate with Windows Task Scheduler

The CLI Workspace provides a powerful, efficient interface for VMware administrators who need fast access to PowerCLI functionality without the overhead of a full GUI application.