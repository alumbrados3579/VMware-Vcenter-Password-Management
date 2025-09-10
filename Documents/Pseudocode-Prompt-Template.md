# Pseudocode Generation Prompt Template
## Professional Pseudocode Creation Guide

### Overview

This prompt template is designed to generate clear, structured, and professional pseudocode for various programming scenarios. Use this template to request pseudocode that follows industry standards and best practices.

### Prompt Template

```
Create detailed pseudocode for the following requirement:

**REQUIREMENT:**
[Describe the specific functionality, algorithm, or process you need pseudocode for]

**CONTEXT:**
- Programming Language/Environment: [Specify target language if relevant]
- Complexity Level: [Simple/Intermediate/Advanced]
- Performance Requirements: [Any specific performance considerations]
- Input Parameters: [List expected inputs and their types]
- Expected Output: [Describe the expected output format and type]

**PSEUDOCODE REQUIREMENTS:**
1. Use clear, descriptive variable names
2. Include proper indentation and structure
3. Add comments for complex logic sections
4. Show error handling where appropriate
5. Include input validation steps
6. Use standard pseudocode conventions
7. Break down complex operations into smaller steps
8. Include loop and conditional logic clearly

**FORMAT SPECIFICATIONS:**
- Use structured English statements
- Employ consistent indentation (2-4 spaces)
- Use standard control structures (IF/THEN/ELSE, WHILE, FOR)
- Include BEGIN/END blocks for clarity
- Add line numbers if requested
- Use meaningful function/procedure names

**ADDITIONAL REQUIREMENTS:**
[Any specific requirements such as:]
- Algorithm optimization focus
- Memory efficiency considerations
- Specific design patterns to follow
- Integration with existing systems
- Security considerations
- Scalability requirements

Please provide the pseudocode with:
1. Clear step-by-step logic flow
2. Proper error handling
3. Input/output specifications
4. Comments explaining complex sections
5. Alternative approaches if applicable
```

### Example Usage

#### Example 1: Simple Algorithm
```
Create detailed pseudocode for the following requirement:

**REQUIREMENT:**
Create a function to calculate the factorial of a positive integer

**CONTEXT:**
- Programming Language/Environment: General purpose
- Complexity Level: Simple
- Performance Requirements: Standard recursive or iterative approach
- Input Parameters: Integer n (positive number)
- Expected Output: Integer result (factorial of n)

**PSEUDOCODE REQUIREMENTS:**
1. Include input validation for positive integers
2. Handle edge cases (0 and 1)
3. Show both recursive and iterative approaches
4. Include error handling for invalid inputs
5. Add comments for clarity

**FORMAT SPECIFICATIONS:**
- Use structured English statements
- Employ consistent 2-space indentation
- Include BEGIN/END blocks
- Use meaningful variable names

**ADDITIONAL REQUIREMENTS:**
- Show time complexity analysis
- Include boundary condition handling
- Demonstrate best practices for integer overflow
```

#### Example 2: Complex System
```
Create detailed pseudocode for the following requirement:

**REQUIREMENT:**
Design a user authentication system with login, logout, and session management

**CONTEXT:**
- Programming Language/Environment: Web application backend
- Complexity Level: Advanced
- Performance Requirements: Handle 1000+ concurrent users
- Input Parameters: Username, password, session tokens
- Expected Output: Authentication status, session data, security tokens

**PSEUDOCODE REQUIREMENTS:**
1. Include comprehensive security measures
2. Show database interaction patterns
3. Implement session timeout handling
4. Add proper error handling and logging
5. Include input sanitization steps
6. Show concurrent access handling
7. Implement rate limiting logic

**FORMAT SPECIFICATIONS:**
- Use structured English with technical terminology
- Employ 4-space indentation for nested structures
- Include detailed function signatures
- Use descriptive procedure names
- Add line numbers for reference

**ADDITIONAL REQUIREMENTS:**
- Security-first approach with encryption
- Scalable session storage design
- Integration with existing user database
- Compliance with authentication standards
- Performance optimization for high load
- Comprehensive audit logging
```

### Pseudocode Standards and Conventions

#### Control Structures
```
IF condition THEN
    statements
ELSE IF condition THEN
    statements
ELSE
    statements
END IF

WHILE condition DO
    statements
END WHILE

FOR variable = start TO end STEP increment DO
    statements
END FOR

REPEAT
    statements
UNTIL condition

SWITCH variable
    CASE value1:
        statements
        BREAK
    CASE value2:
        statements
        BREAK
    DEFAULT:
        statements
END SWITCH
```

#### Function/Procedure Definitions
```
FUNCTION functionName(parameter1: type, parameter2: type) RETURNS returnType
BEGIN
    DECLARE localVariable: type
    
    // Function logic here
    
    RETURN result
END FUNCTION

PROCEDURE procedureName(parameter1: type, parameter2: type)
BEGIN
    // Procedure logic here
END PROCEDURE
```

#### Variable Declarations and Assignments
```
DECLARE variableName: dataType
DECLARE arrayName: ARRAY[size] OF dataType
DECLARE recordName: RECORD
    field1: type
    field2: type
END RECORD

SET variableName = value
SET arrayName[index] = value
```

#### Input/Output Operations
```
INPUT variableName
OUTPUT "message" + variableName
PRINT "formatted output"
READ fileName INTO variableName
WRITE variableName TO fileName
```

#### Error Handling
```
TRY
    // Risky operations
CATCH exceptionType
    // Error handling
FINALLY
    // Cleanup operations
END TRY

IF error_condition THEN
    THROW new Exception("error message")
END IF
```

### Best Practices for Pseudocode Requests

#### 1. Be Specific About Requirements
- Clearly define the problem scope
- Specify input and output formats
- Include any constraints or limitations
- Mention performance requirements

#### 2. Indicate Complexity Level
- Simple: Basic algorithms, single functions
- Intermediate: Multiple functions, moderate logic
- Advanced: Complex systems, multiple components

#### 3. Specify Context
- Target programming paradigm (OOP, functional, procedural)
- Integration requirements
- Platform or environment constraints
- Existing system dependencies

#### 4. Request Appropriate Detail Level
- High-level overview for system design
- Detailed steps for algorithm implementation
- Specific error handling requirements
- Performance optimization considerations

#### 5. Include Quality Requirements
- Code readability and maintainability
- Security considerations
- Scalability requirements
- Testing and validation approaches

### Common Pseudocode Patterns

#### Algorithm Design
```
ALGORITHM algorithmName
INPUT: parameter descriptions
OUTPUT: result description
PRECONDITIONS: assumptions and requirements
POSTCONDITIONS: guaranteed results

BEGIN
    // Step-by-step algorithm logic
END
```

#### Data Structure Operations
```
STRUCTURE dataStructureName
    // Field definitions
    
    OPERATION operationName(parameters)
    BEGIN
        // Operation logic
    END
    
END STRUCTURE
```

#### System Design
```
SYSTEM systemName
    COMPONENTS:
        component1: description
        component2: description
    
    INTERFACES:
        interface1: specification
        interface2: specification
    
    WORKFLOWS:
        workflow1: step-by-step process
        workflow2: step-by-step process
        
END SYSTEM
```

### Usage Guidelines

1. **Customize the Template**: Modify the prompt template based on your specific needs
2. **Provide Clear Context**: Include all relevant information about the problem domain
3. **Specify Detail Level**: Indicate how detailed the pseudocode should be
4. **Include Examples**: Provide sample inputs/outputs when helpful
5. **Request Alternatives**: Ask for multiple approaches when appropriate
6. **Emphasize Quality**: Specify requirements for clarity, efficiency, and maintainability

This template ensures you receive high-quality, professional pseudocode that meets your specific requirements and follows industry standards.