build_name_overwrite = ""
# Empty = No overwrite by default

import argparse
import os
import zipfile

parser = argparse.ArgumentParser(description="Builds the plugin and creates an .op file.")
parser.add_argument('-s', '--sanitize', action='store_true', help='Enable filename sanitization.')
parser.add_argument('-o', '--overwrite-name', type=str, default=build_name_overwrite, help='Specify a custom name for the output file.')
args = parser.parse_args()

def sanitize_filename(filename):
    return filename.replace("_", "").replace("-", "")

def zip_directory(src_dir, zip_file):
    for root, dirs, files in os.walk(src_dir):
        for file in files:
            sanitized_file = sanitize_filename(file) if args.sanitize else file
            file_path = os.path.join(root, file)
            sanitized_file_path = os.path.join(root, sanitized_file)
            zip_file.write(file_path, os.path.relpath(sanitized_file_path, os.path.join(src_dir, '..')))

def create_op_file():
    top_dir_name = os.path.basename(os.getcwd())
    op_file_name = args.overwrite_name if args.overwrite_name else sanitize_filename(top_dir_name)
    op_file_name += ".op"

    with zipfile.ZipFile(op_file_name, 'w', zipfile.ZIP_DEFLATED) as zipf:
        zip_directory('./src', zipf)

        additional_files = ['info.toml', 'LICENSE', 'README.md']
        for file in additional_files:
            if os.path.exists(file):
                sanitized_file = sanitize_filename(file) if args.sanitize else file
                zipf.write(file, sanitized_file)

    print(f"Created {op_file_name} successfully.")
    print(f"\033[31mIMPORTANT: Enable showDefaultLogs, in src/Condictions/Logging.as so the logs are uniform\033[0m")

if __name__ == "__main__":
    create_op_file()
