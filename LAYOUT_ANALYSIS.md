# VMware Password Manager - Layout Analysis

## Current Layout Issues

### vCenter Connection Group (Current)
```
┌─ vCenter Connection ─────────────────────────────────────────────────────────┐
│                                                                              │
│ vCenter Server:     [textbox]     Admin Username:     [textbox]     Password:│
│ (10,25)            (120,23)       (340,25)           (450,23)       (610,25) │
│ 100px wide         200px wide     100px wide         180px wide     70px wide│
│                                                                              │
│                                                       [password textbox]    │
│                                                       (690,23) 140px wide   │
│                                                                              │
│ [Test Connection]  Status: Not Connected                                    │
│ (10,60)           (150,65)                                                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Password Operations Group (Current)
```
┌─ Password Operations ────────────────────────────────────────────────────────┐
│                                                                              │
│ Target ESXi User:   [dropdown]    New Password:    [textbox]    Confirm:    │
│ (10,25)            (120,23)       (240,25)         (350,23)     (520,25)    │
│ 100px wide         120px wide     100px wide       150px wide   60px wide   │
│                                                                              │
│                                                     [confirm textbox]       │
│                                                     (590,23) 150px wide     │
│                                                                              │
│ [Dry Run]  [LIVE Run]                                                       │
│ (10,70)    (140,70)                                                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Problems Identified

1. **Password field visibility**: The "Password:" label is too close to the textbox edge
2. **Inconsistent spacing**: Labels and textboxes have varying gaps
3. **Cramped layout**: Fields are too close together horizontally
4. **Poor alignment**: Labels don't align well with their textboxes

## Proposed Improved Layout

### vCenter Connection Group (Improved)
```
┌─ vCenter Connection ─────────────────────────────────────────────────────────┐
│                                                                              │
│ vCenter Server:   [textbox]      Username:      [textbox]      Password:    │
│ (10,25)          (110,23)        (330,25)       (410,23)       (580,25)     │
│ 100px wide       180px wide      80px wide      150px wide     80px wide    │
│                                                                              │
│                                                                [textbox]    │
│                                                                (670,23)     │
│                                                                160px wide   │
│                                                                              │
│ [Test Connection]  Status: Not Connected                                    │
│ (10,60)           (150,65)                                                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Password Operations Group (Improved)
```
┌─ Password Operations ────────────────────────────────────────────────────────┐
│                                                                              │
│ Target User:      [dropdown]      New Password:    [textbox]    Confirm:    │
│ (10,25)          (100,23)         (230,25)         (330,23)     (490,25)    │
│ 90px wide        130px wide       100px wide       150px wide   70px wide   │
│                                                                              │
│                                                                 [textbox]   │
│                                                                 (570,23)    │
│                                                                 150px wide  │
│                                                                              │
│ [Dry Run]  [LIVE Run]                                                       │
│ (10,70)    (140,70)                                                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Key Improvements

1. **Better spacing**: 10px gap between label and textbox consistently
2. **Clearer labels**: Shortened "Admin Username" to "Username" for space
3. **Better password visibility**: Moved password field left with more space
4. **Consistent alignment**: All labels and textboxes properly aligned
5. **More breathing room**: Increased spacing between field groups

## Exact Positioning Changes

### vCenter Connection:
- vCenter Server Label: (10,25) → (10,25) [no change]
- vCenter Server TextBox: (120,23) → (110,23) [closer to label]
- Username Label: (340,25) → (330,25) [moved left]
- Username TextBox: (450,23) → (410,23) [closer to label]
- Password Label: (610,25) → (580,25) [moved left for visibility]
- Password TextBox: (690,23) → (670,23) [closer to label]

### Password Operations:
- Target User Label: (10,25) → (10,25) [no change]
- Target User ComboBox: (120,23) → (100,23) [closer to label]
- New Password Label: (240,25) → (230,25) [moved left]
- New Password TextBox: (350,23) → (330,23) [closer to label]
- Confirm Label: (520,25) → (490,25) [moved left]
- Confirm TextBox: (590,23) → (570,23) [closer to label]

This layout provides better visual balance and ensures all labels are clearly visible with their corresponding input fields.