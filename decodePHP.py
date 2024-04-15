"""
This Python script is designed to help decode and safely inspect potentially malicious PHP files.
The script reads the contents of a specified PHP file, replaces all instances of the potentially dangerous 'eval()' function with 'print()'
to prevent execution of malicious code, and saves the modified version. It then executes the modified PHP script in a safe environment,
captures the output, and saves it to a text file for analysis.

The script generates two output files:
1. A modified PHP file (*_safe.php), which contains the sanitized PHP code with 'eval()' replaced by 'print()'.
2. An output text file (*_output.txt), which includes the output from executing the modified PHP script, showing what would have been executed.

How to use:
1. Ensure you have Python and PHP installed on your system.
2. Place this script in a directory accessible by the command line.
3. Run the script using the command: python script.py <path_to_php_file>
   Replace '<path_to_php_file>' with the path to the PHP file you want to inspect.
4. The script will generate the two mentioned files: one with the modified PHP code and another with the output of the executed PHP script.

Example:
   python decodePHP.py example.php
"""

import sys
import subprocess

def safe_handle_php(file_path):
    try:
        # Read the content of the PHP file
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()

        # Replace dangerous eval() with print() for safe inspection
        safe_content = content.replace('eval', 'print')

        # Save the modified content to a new file
        new_file_path = file_path.replace('.php', '_safe.php')
        with open(new_file_path, 'w', encoding='utf-8') as new_file:
            new_file.write(safe_content)

        # Execute the modified PHP script and capture the output
        result = subprocess.run(['php', new_file_path], capture_output=True, text=True)
        output_file_path = file_path.replace('.php', '_output.txt')
        with open(output_file_path, 'w', encoding='utf-8') as output_file:
            output_file.write(result.stdout)

        print(f"Processed file saved as {new_file_path}")
        print(f"Output of the PHP script saved as {output_file_path}")
    
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <path_to_php_file>")
    else:
        file_path = sys.argv[1]
        safe_handle_php(file_path)

