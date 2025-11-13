"""
This file intentionally contains code quality issues to demonstrate
SonarQube quality gate failure.
"""

import os
import sys

# Unused imports - code smell
import json
import time
import random

def poorly_written_function(a, b, c, d, e, f):
    """Function with too many parameters and high complexity."""
    
    # Bare except - critical security issue
    try:
        result = a / b
    except:
        pass
    
    # High cyclomatic complexity - code smell
    if a > 0:
        if b > 0:
            if c > 0:
                if d > 0:
                    if e > 0:
                        if f > 0:
                            return "deeply nested"
    
    # Duplicate code blocks - maintainability issue
    x = a + b + c
    y = a + b + c
    z = a + b + c
    
    # Security hotspot - hardcoded credentials
    password = "admin123"
    api_key = "secret_key_12345"
    
    # Unused variables
    unused1 = 10
    unused2 = 20
    unused3 = 30
    
    return x + y + z

def another_complex_function():
    """Another poorly written function."""
    
    # More bare excepts
    try:
        file = open("/tmp/test.txt")
    except:
        print("error")
    
    # SQL injection vulnerability pattern
    user_input = "admin"
    query = "SELECT * FROM users WHERE name = '" + user_input + "'"
    
    # More nested conditions
    for i in range(10):
        for j in range(10):
            for k in range(10):
                if i > j:
                    if j > k:
                        print("nested loops")

# No if __name__ == "__main__" guard
poorly_written_function(1, 2, 3, 4, 5, 6)
another_complex_function()
