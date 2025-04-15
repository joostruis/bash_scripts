# bash_scripts

A collection of useful, practical Bash scripts for Linux systems. These scripts are written to be readable, efficient, and easy to extend. They’re primarily aimed at system administrators, power users, and developers who work with Linux regularly.

## Included Scripts

scan-broken-libs.sh  
  Scans common system directories for ELF binaries with missing shared library dependencies using ldd. Helps identify broken system packages or orphaned files.

  - Skips known false positives (e.g., plugin folders, dynamically loaded modules)
  - Scans /usr, /lib, /bin, /sbin, etc.
  - Separates definitely broken from possibly ignorable issues
  - MIT Licensed

More scripts will be added over time.

## Usage

1. Clone the repository:

   git clone https://github.com/joostruis/bash_scripts.git
   cd bash_scripts

2. Make a script executable:

   chmod +x scriptname.sh

3. Run it:

   ./scriptname.sh

Note: Some scripts may require sudo, depending on what they scan or modify.

## Contributing

Contributions are welcome! Feel free to submit issues, suggestions, or pull requests.

## License

All scripts in this repository are released under the MIT License.

## Author

Joost Ruis  
joost.ruis@mocaccino.org  
https://mocaccino.org
