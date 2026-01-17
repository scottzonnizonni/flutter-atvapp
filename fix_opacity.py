import os
import re

# Directory to search
lib_dir = r'd:\Dev\APP\ProjetosFlutter\2\flutter_application_1\lib'

# Pattern to match .withOpacity(value)
pattern = r'\.withOpacity\(([0-9.]+)\)'
replacement = r'.withValues(alpha: \1)'

# Counter
files_modified = 0
total_replacements = 0

# Walk through all .dart files
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            file_path = os.path.join(root, file)
            
            # Read file
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace
            new_content, count = re.subn(pattern, replacement, content)
            
            if count > 0:
                # Write back
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                
                files_modified += 1
                total_replacements += count
                print(f'Modified {file}: {count} replacements')

print(f'\nTotal: {total_replacements} replacements in {files_modified} files')
