# 📊 VMware vCenter Password Management - Workflow Diagrams

## System Architecture Overview

```mermaid
graph TB
    subgraph "User Interface Layer"
        A[Main GUI Application]
        B[DoD Warning Banners]
        C[Progress Tracking]
    end
    
    subgraph "Application Logic Layer"
        D[vCenter Connection Manager]
        E[Password Change Engine]
        F[GitHub Integration Manager]
        G[Security & Audit System]
    end
    
    subgraph "External Systems"
        H[VMware vCenter Server]
        I[ESXi Hosts]
        J[GitHub Repository]
        K[PowerShell Gallery]
    end
    
    subgraph "Local Storage"
        L[Configuration Files]
        M[Log Files]
        N[Audit Trail]
    end
    
    A --> D
    A --> F
    B --> G
    C --> E
    
    D --> H
    E --> I
    F --> J
    F --> K
    
    G --> M
    G --> N
    D --> L
```

## Installation Workflow

```mermaid
flowchart TD
    A[Start Installation] --> B[Show DoD Warning]
    B --> C[User Acknowledges]
    C --> D[Check Prerequisites]
    
    D --> E{Prerequisites Met?}
    E -->|No| F[Show Issues & Recommendations]
    F --> G{Continue Anyway?}
    G -->|No| H[Exit Installation]
    G -->|Yes| I[Show Installation Options]
    E -->|Yes| I
    
    I --> J{Installation Type}
    J -->|Full| K[Download All Components + Modules.zip]
    J -->|Scripts Only| L[Download Scripts & Docs Only]
    J -->|Custom| M[User Selects Components]
    
    K --> N[Create Directory Structure]
    L --> N
    M --> N
    
    N --> O[Download Selected Files]
    O --> P[Create Configuration Files]
    P --> Q[Create Desktop Shortcut]
    Q --> R[Installation Complete]
    
    R --> S[Show Success Message]
    S --> T[Open Installation Directory?]
    T -->|Yes| U[Open Directory]
    T -->|No| V[End]
    U --> V
```

## Main Application Workflow

```mermaid
flowchart TD
    A[Launch Application] --> B[Show DoD Warning]
    B --> C[User Acknowledges]
    C --> D[Initialize Logging]
    D --> E[Load Configuration]
    E --> F[Show Main Interface]
    
    F --> G{User Action}
    
    G -->|vCenter Tab| H[vCenter Management Workflow]
    G -->|GitHub Tab| I[GitHub Management Workflow]
    G -->|Exit| J[Cleanup & Exit]
    
    H --> K[Test vCenter Connection]
    K --> L{Connection Success?}
    L -->|Yes| M[Discover ESXi Hosts]
    L -->|No| N[Show Error & Retry]
    N --> K
    
    M --> O[Configure Password Change]
    O --> P{Operation Mode}
    P -->|Dry Run| Q[Execute Simulation]
    P -->|Live Mode| R[Show Security Warning]
    
    Q --> S[Display Results]
    R --> T{User Confirms?}
    T -->|Yes| U[Execute Live Operation]
    T -->|No| V[Cancel Operation]
    
    U --> S
    V --> F
    S --> F
    
    I --> W[GitHub Operations Workflow]
    W --> F
    
    J --> X[Clear Sensitive Data]
    X --> Y[Save Logs]
    Y --> Z[End Application]
```

## Password Change Operation Workflow

```mermaid
sequenceDiagram
    participant User
    participant GUI
    participant App
    participant vCenter
    participant ESXi1
    participant ESXi2
    participant Logs
    
    User->>GUI: Enter vCenter credentials
    GUI->>App: Validate input
    App->>vCenter: Test connection
    vCenter-->>App: Connection successful
    App->>vCenter: Get ESXi hosts
    vCenter-->>App: Return host list
    App->>GUI: Display hosts
    
    User->>GUI: Configure password change
    User->>GUI: Select Dry Run mode
    GUI->>App: Execute dry run
    
    App->>Logs: Log operation start
    
    loop For each selected host
        App->>vCenter: Connect to ESXi via vCenter
        vCenter->>ESXi1: Simulate password change
        ESXi1-->>vCenter: Simulation result
        vCenter-->>App: Return result
        App->>Logs: Log simulation result
        App->>GUI: Update progress
    end
    
    App->>GUI: Display simulation results
    
    User->>GUI: Switch to Live Mode
    GUI->>App: Show security warning
    App->>User: Display DoD warning
    User->>App: Confirm operation
    
    App->>Logs: Log live operation start
    
    loop For each selected host
        App->>vCenter: Connect to ESXi via vCenter
        vCenter->>ESXi1: Change password
        ESXi1-->>vCenter: Operation result
        vCenter-->>App: Return result
        App->>Logs: Log operation result
        App->>GUI: Update progress
    end
    
    App->>GUI: Display final results
    App->>Logs: Log operation complete
```

## GitHub Integration Workflow

```mermaid
flowchart TD
    A[GitHub Manager Tab] --> B[Enter Personal Access Token]
    B --> C[Validate Token]
    C --> D{Token Valid?}
    
    D -->|No| E[Show Error Message]
    E --> B
    
    D -->|Yes| F[Retrieve Username]
    F --> G[Enable Repository Operations]
    
    G --> H{User Action}
    
    H -->|Push to GitHub| I[Select Files to Upload]
    I --> J[Exclude Modules.zip]
    J --> K[Start Upload Process]
    K --> L[Show Progress]
    L --> M[Upload Complete]
    
    H -->|Download Latest| N[Fetch Latest Version]
    N --> O[Download Scripts & Docs]
    O --> P[Preserve Local Config]
    P --> Q[Update Complete]
    
    M --> R[Return to Main Interface]
    Q --> R
```

## Security & Audit Workflow

```mermaid
flowchart TD
    A[User Action] --> B[Security Check]
    B --> C{Sensitive Operation?}
    
    C -->|No| D[Log Action]
    C -->|Yes| E[Show Security Warning]
    
    E --> F{User Confirms?}
    F -->|No| G[Log Denial]
    F -->|Yes| H[Log Authorization]
    
    D --> I[Execute Operation]
    G --> J[Cancel Operation]
    H --> I
    
    I --> K[Log Operation Start]
    K --> L[Execute with Monitoring]
    L --> M[Log Operation Result]
    M --> N{Operation Success?}
    
    N -->|Yes| O[Log Success]
    N -->|No| P[Log Failure]
    
    O --> Q[Update Audit Trail]
    P --> Q
    J --> Q
    
    Q --> R[Filter Sensitive Data]
    R --> S[Write to Log File]
    S --> T[Return to Application]
```

## Error Handling Workflow

```mermaid
flowchart TD
    A[Operation Starts] --> B[Try Operation]
    B --> C{Error Occurs?}
    
    C -->|No| D[Operation Success]
    C -->|Yes| E[Catch Error]
    
    E --> F[Log Error Details]
    F --> G[Clean Sensitive Data]
    G --> H{Critical Error?}
    
    H -->|Yes| I[Show Critical Error Dialog]
    H -->|No| J[Show Standard Error Message]
    
    I --> K[Attempt Recovery]
    J --> L[Suggest Solutions]
    
    K --> M{Recovery Success?}
    M -->|Yes| N[Continue Operation]
    M -->|No| O[Graceful Shutdown]
    
    L --> P{User Retries?}
    P -->|Yes| B
    P -->|No| Q[Cancel Operation]
    
    D --> R[Log Success]
    N --> R
    O --> S[Log Shutdown]
    Q --> T[Log Cancellation]
    
    R --> U[Return to Main Interface]
    S --> V[Exit Application]
    T --> U
```

## Data Flow Diagram

```mermaid
flowchart LR
    subgraph "Input Sources"
        A[User Input]
        B[Configuration Files]
        C[vCenter Server]
    end
    
    subgraph "Processing Engine"
        D[Input Validation]
        E[Security Checks]
        F[Operation Logic]
        G[Result Processing]
    end
    
    subgraph "Output Destinations"
        H[GUI Display]
        I[Log Files]
        J[ESXi Hosts]
        K[GitHub Repository]
    end
    
    A --> D
    B --> D
    C --> D
    
    D --> E
    E --> F
    F --> G
    
    G --> H
    G --> I
    F --> J
    F --> K
    
    style A fill:#e1f5fe
    style B fill:#e8f5e8
    style C fill:#fff3e0
    style H fill:#f3e5f5
    style I fill:#fce4ec
    style J fill:#e0f2f1
    style K fill:#fff8e1
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Development Environment"
        A[Developer Workstation]
        B[Local Testing]
        C[GitHub Repository]
    end
    
    subgraph "Distribution Methods"
        D[Startup Script Download]
        E[GitHub Release]
        F[Manual Distribution]
    end
    
    subgraph "Target Environments"
        G[NIPR/Internet Connected]
        H[SIPR/Air-gapped]
        I[Corporate Networks]
    end
    
    subgraph "Installation Types"
        J[Full Installation + Modules.zip]
        K[Scripts Only]
        L[Custom Selection]
    end
    
    A --> C
    B --> C
    C --> D
    C --> E
    C --> F
    
    D --> G
    E --> G
    E --> H
    F --> H
    F --> I
    
    G --> J
    G --> K
    H --> L
    I --> J
    I --> K
```

## Security Model

```mermaid
flowchart TD
    subgraph "Authentication Layers"
        A[Windows User Authentication]
        B[vCenter Authentication]
        C[GitHub Token Authentication]
    end
    
    subgraph "Authorization Controls"
        D[DoD Warning Acknowledgment]
        E[Operation Mode Selection]
        F[Multi-Level Confirmations]
    end
    
    subgraph "Data Protection"
        G[Credential Encryption]
        H[Secure Memory Handling]
        I[Audit Log Filtering]
    end
    
    subgraph "Network Security"
        J[TLS/SSL Encryption]
        K[Certificate Validation]
        L[Secure Protocols]
    end
    
    A --> D
    B --> E
    C --> F
    
    D --> G
    E --> H
    F --> I
    
    G --> J
    H --> K
    I --> L
```

## Monitoring & Alerting

```mermaid
flowchart TD
    A[Application Events] --> B[Event Classification]
    B --> C{Event Type}
    
    C -->|Normal| D[Standard Logging]
    C -->|Warning| E[Warning Logging]
    C -->|Error| F[Error Logging]
    C -->|Security| G[Security Logging]
    
    D --> H[Log File]
    E --> H
    F --> H
    G --> I[Security Audit Log]
    
    H --> J[Log Rotation]
    I --> K[Security Monitoring]
    
    J --> L[Archive Logs]
    K --> M[Alert Generation]
    
    M --> N{Alert Level}
    N -->|Info| O[Information Alert]
    N -->|Warning| P[Warning Alert]
    N -->|Critical| Q[Critical Alert]
    
    O --> R[Log Alert]
    P --> S[Notify Administrator]
    Q --> T[Immediate Response Required]
```

---

These workflow diagrams provide a comprehensive view of how the VMware vCenter Password Management Tool operates, from installation through daily operations, security controls, and monitoring. Each diagram focuses on a specific aspect of the system to help users and administrators understand the complete workflow and security model.