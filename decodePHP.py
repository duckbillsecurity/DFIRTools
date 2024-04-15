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
