# VMware vCenter Password Management Tool - Changelog

## Version 0.5 BETA - Latest Updates

### 🎯 Major UI Improvements (Latest Release)

#### ✅ Progress Bar Display Fixed
- **Issue**: Unicode characters (█░) not displaying correctly in terminals
- **Fix**: Replaced with ASCII characters (= ) for universal compatibility
- **Result**: Clean progress bars: `[===============     ] 67%`

#### ✅ Password Field Visibility Fixed
- **Issue**: "Password" label was clobbered and barely visible
- **Fix**: Changed to "Admin Password:" with better positioning
- **Result**: Clear, readable password field labels

#### ✅ Window Resizability Restored
- **Issue**: Window was not resizable anymore
- **Fix**: Changed from FixedDialog to Sizable with MaximizeBox enabled
- **Result**: Fully resizable application window with minimum size protection

#### ✅ Detailed Progress Window Enhanced
- **Issue**: Progress window too small to read details
- **Fix**: TRIPLED the height from 70px to 170px
- **Result**: Much better visibility for operation details and logging

#### ✅ Configuration Tab Line Formatting Fixed
- **Issue**: All entries jumbled on one line behind comment marks
- **Fix**: Proper line breaks using PowerShell here-strings
- **Result**: Each host/user entry appears on separate lines as intended

#### ✅ Interactive CLI Workspace Enhanced
- **Feature**: True terminal-like experience added
- **Capabilities**:
  - Press ENTER to execute commands (no button needed)
  - UP/DOWN arrows for command history (last 50 commands)
  - Built-in 'help' and 'clear' commands
  - Auto-focus returns to command input
  - Better error messages and connection guidance

#### ✅ Test Startup Script Added
- **File**: `Test-Startup.ps1` for quick development testing
- **Purpose**: Bypass full setup for faster testing cycles
- **Features**: Safety warnings, requirements check, direct GUI launch

### 🔧 Technical Improvements

#### Progress Bar Compatibility
```powershell
# Before (Unicode issues):
$progressChar = "█"
$emptyChar = "░"

# After (Universal compatibility):
$progressChar = "="
$emptyChar = " "
```

#### GUI Layout Improvements
```powershell
# Window now resizable:
$form.FormBorderStyle = "Sizable"
$form.MaximizeBox = $true
$form.MinimumSize = New-Object System.Drawing.Size(900, 700)

# Progress window tripled in size:
$script:OperationStatusTextBox.Size = New-Object System.Drawing.Size(820, 170)  # Was 70px
```

#### Configuration File Formatting
```powershell
# Before (All on one line):
$script:HostsTextBox.Text = "# ESXi Hosts Configuration`r`n# Add your ESXi host IP addresses..."

# After (Proper line breaks):
$defaultHosts = @"
# ESXi Hosts Configuration
# Add your ESXi host IP addresses or FQDNs below
# One host per line, comments start with #

# Examples:
# 192.168.1.100
# 192.168.1.101
"@
```

#### Interactive CLI Features
```powershell
# Command history with arrow keys:
if ($_.KeyCode -eq "Up") {
    # Navigate to previous command
}

# Built-in commands:
if ($command -eq "clear") { /* Clear terminal */ }
if ($command -eq "help") { /* Show help */ }

# Auto-focus after execution:
$script:CLICommandTextBox.Focus()
```

### 🚀 User Experience Enhancements

#### Before vs After

**Progress Bars:**
- Before: `[â–ˆâ–ˆâ–ˆâ–'â–'â–'] 67%` (broken Unicode)
- After: `[===============     ] 67%` (clean ASCII)

**Password Field:**
- Before: "Password:" (clobbered/barely visible)
- After: "Admin Password:" (clear and properly positioned)

**Window:**
- Before: Fixed size, not resizable
- After: Fully resizable with maximize button

**Progress Details:**
- Before: 70px height (hard to read)
- After: 170px height (3x larger, easy to read)

**Configuration:**
- Before: All entries on one line with comments
- After: Proper line-by-line formatting

**CLI Workspace:**
- Before: Type command → Click Execute button
- After: Type command → Press ENTER (like real terminal)
- Added: Command history, built-in help, auto-focus

### 📁 New Files

#### Test-Startup.ps1
Quick test launcher for development:
```powershell
# Usage:
.\Test-Startup.ps1
# Type 'TEST' to launch GUI directly
```

### 🎉 Summary

All reported issues have been resolved:
- ✅ Progress bar display fixed
- ✅ Password field visibility restored
- ✅ Window resizability enabled
- ✅ Progress window tripled in size
- ✅ Configuration formatting fixed
- ✅ Interactive CLI workspace enhanced
- ✅ Test startup script added

The VMware vCenter Password Management Tool now provides a professional, 
user-friendly experience with true terminal-like CLI capabilities!