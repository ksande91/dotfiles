# Update Prompt

## Overview

The **Update Prompt** is a terminal-based utility designed to facilitate system updates on Linux systems using the `yay` package manager. It provides a simple Text User Interface (TUI) to prompt users for confirmation before proceeding with the update process.

## Features

- **Interactive TUI**: Uses the Bubble Tea framework to create an interactive terminal interface.
- **System Update**: Executes the `yay -Syu` command to update the system packages.
- **User Confirmation**: Prompts the user to confirm whether they want to proceed with the update.
- **Graceful Exit**: Ensures the terminal session remains open after the update process for user review.

## Prerequisites

- **Go**: Ensure Go is installed on your system. You can download it from [golang.org](https://golang.org/dl/).
- **yay**: The `yay` package manager must be installed for the update process.

## Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/yourusername/update-prompt.git
   cd update-prompt
   ```

2. **Build the Program**:
   ```bash
   go build update_prompt.go
   ```

## Usage

Run the program using the following command:

```bash
./update_prompt
```

Upon execution, the program will display a prompt asking if you would like to update the system. Respond with 'y' to proceed or 'n' to skip the update.

## Files

- `update_prompt.go`: The main Go program file.
- `startup_update_prompt.sh`: A script to run the program at startup.
- `go.mod` and `go.sum`: Go module files for dependency management.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Bubble Tea](https://github.com/charmbracelet/bubbletea) for the TUI framework.
- [Lip Gloss](https://github.com/charmbracelet/lipgloss) for styling the terminal output.
