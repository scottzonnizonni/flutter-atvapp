import re

# Fix qr_scanner_screen.dart - add mounted check before Navigator
file_path = r'd:\Dev\APP\ProjetosFlutter\2\flutter_application_1\lib\screens\qr_scanner_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the problematic section
old_pattern = r'''    if \(content != null && mounted\) \{
      // Add to history
      await historyProvider\.addScan\(content\.id, content\.qrCodeId\);

      // Navigate to content detail
      Navigator\.of\(context\)\.pushReplacement\('''

new_pattern = '''    if (content != null && mounted) {
      // Add to history
      await historyProvider.addScan(content.id, content.qrCodeId);

      // Check mounted again before navigation
      if (!mounted) return;
      
      // Navigate to content detail
      Navigator.of(context).pushReplacement('''

content = content.replace(old_pattern.replace('\\', ''), new_pattern)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed qr_scanner_screen.dart")

# Fix content_form_screen.dart - change value to initialValue
file_path2 = r'd:\Dev\APP\ProjetosFlutter\2\flutter_application_1\lib\screens\content_form_screen.dart'

with open(file_path2, 'r', encoding='utf-8') as f:
    content2 = f.read()

# Replace value with initialValue in DropdownButtonFormField
content2 = re.sub(
    r'(\s+)DropdownButtonFormField<String>\(\s*\n\s+value: _selectedCategory,',
    r'\1DropdownButtonFormField<String>(\n\1  initialValue: _selectedCategory,',
    content2
)

with open(file_path2, 'w', encoding='utf-8') as f:
    f.write(content2)

print("Fixed content_form_screen.dart")
