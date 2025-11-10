import re

with open("assign.md", "r", encoding="utf-8") as f:
    content = f.read()

# Remove <br> tags
content = re.sub(r"<br\s*/?>", " — ", content)

# Re-collapse multi-space sequences
content = re.sub(r"\s{2,}", " ", content)

with open("table_clean.md", "w", encoding="utf-8") as f:
    f.write(content)

print("✅ table_clean.md generated.")
