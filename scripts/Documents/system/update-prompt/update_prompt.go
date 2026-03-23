package main

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type model struct {
	quitting  bool
	message   string
	spinner   spinner.Model
	runUpdate bool // Flag to indicate whether to run the update
}

var (
	titleStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#7D56F4")).
			Background(lipgloss.Color("#1E1E1E")).
			Padding(1, 2).
			Bold(true)

	questionStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#00FFCC")).
			Bold(true)

	messageStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FF5555"))
)

func initialModel() model {
	sp := spinner.New()
	sp.Spinner = spinner.Line
	return model{
		spinner: sp,
	}
}

func (m model) Init() tea.Cmd {
	return m.spinner.Tick
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "y", "Y":
			m.quitting = true
			m.runUpdate = true // Set flag to true to run the update
			m.message = "Running system update...\n"
			return m, tea.Quit // Stop the TUI before executing the command

		case "n", "N":
			m.message = "Update skipped.\n"
			m.quitting = true
			m.runUpdate = false // Set flag to false to skip the update
			return m, tea.Quit  // Exit TUI

		case "ctrl+c", "q":
			m.message = "Exiting...\n"
			m.quitting = true
			m.runUpdate = false // Set flag to false
			return m, tea.Quit  // Exit TUI
		}

	case tea.WindowSizeMsg:
		// Handle resizing if needed

	default:
		m.spinner, cmd = m.spinner.Update(msg)
	}

	return m, cmd
}

func (m model) View() string {
	if m.quitting {
		return messageStyle.Render(m.message)
	}

	header := titleStyle.Render("🔄 System Update Utility")
	question := questionStyle.Render("Would you like to update the system? (y/n)\n")
	loading := m.spinner.View()

	return fmt.Sprintf("%s\n\n%s\n\n%s", header, question, loading)
}

func main() {
	// Run the TUI program
	m := initialModel()
	p := tea.NewProgram(m)

	finalModel, err := p.Run()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	// TUI has exited; check if we should run the update
	if finalModel.(model).runUpdate {
		runCommand()
	} else {
		fmt.Println("No updates were performed.")
	}
}

// runCommand executes the external `yay` command in a clean terminal
func runCommand() {
	fmt.Println("Starting the system update...")

	// Run the `yay` command
	cmd := exec.Command("yay", "-Syu")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	// Execute the command and handle errors
	if err := cmd.Run(); err != nil {
		fmt.Printf("Error updating system: %v\n", err)
	} else {
		fmt.Println("\nSystem update completed successfully!")
	}

	// Wait for the user to acknowledge before exiting
	fmt.Println("\nPress Enter to exit...")
	fmt.Scanln()
	// Attempt to quit the terminal
	fmt.Println("\nClosing terminal...")

	// Send a command to quit the terminal
	exitCmd := exec.Command("sh", "-c", "exit")
	exitCmd.Stdout = os.Stdout
	exitCmd.Stderr = os.Stderr

	if err := exitCmd.Run(); err != nil {
		fmt.Printf("Error closing terminal: %v\n", err)
	} else {
		fmt.Println("Terminal closed.")
	}

	// Use os.Exit to ensure the program itself exits
	os.Exit(0)
}
