package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type step int

const (
	stepSystemUpdate step = iota
	stepDotfilesUpdate
	stepDone
)

type model struct {
	quitting       bool
	message        string
	spinner        spinner.Model
	currentStep    step
	runUpdate      bool
	runDotfiles    bool
	dotfilesAvail  bool
	dotfilesChanges string
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

	infoStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#AAAAAA"))
)

func checkDotfilesUpdates() (bool, string) {
	dotfiles := os.Getenv("HOME") + "/dotfiles"

	fetch := exec.Command("git", "-C", dotfiles, "fetch", "origin", "main")
	fetch.Stderr = nil
	fetch.Stdout = nil
	if err := fetch.Run(); err != nil {
		return false, ""
	}

	local, err := exec.Command("git", "-C", dotfiles, "rev-parse", "HEAD").Output()
	if err != nil {
		return false, ""
	}
	remote, err := exec.Command("git", "-C", dotfiles, "rev-parse", "origin/main").Output()
	if err != nil {
		return false, ""
	}

	if strings.TrimSpace(string(local)) == strings.TrimSpace(string(remote)) {
		return false, ""
	}

	changes, _ := exec.Command("git", "-C", dotfiles, "log", "--oneline", "HEAD..origin/main").Output()
	return true, strings.TrimSpace(string(changes))
}

func initialModel() model {
	sp := spinner.New()
	sp.Spinner = spinner.Line

	avail, changes := checkDotfilesUpdates()

	return model{
		spinner:         sp,
		currentStep:     stepSystemUpdate,
		dotfilesAvail:   avail,
		dotfilesChanges: changes,
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
			if m.currentStep == stepSystemUpdate {
				m.runUpdate = true
				if m.dotfilesAvail {
					m.currentStep = stepDotfilesUpdate
				} else {
					m.quitting = true
					m.message = "Running system update...\n"
					return m, tea.Quit
				}
			} else if m.currentStep == stepDotfilesUpdate {
				m.runDotfiles = true
				m.quitting = true
				m.message = "Running system update + dotfiles update...\n"
				return m, tea.Quit
			}

		case "n", "N":
			if m.currentStep == stepSystemUpdate {
				if m.dotfilesAvail {
					m.currentStep = stepDotfilesUpdate
				} else {
					m.message = "Updates skipped.\n"
					m.quitting = true
					return m, tea.Quit
				}
			} else if m.currentStep == stepDotfilesUpdate {
				m.quitting = true
				if m.runUpdate {
					m.message = "Running system update...\n"
				} else {
					m.message = "Updates skipped.\n"
				}
				return m, tea.Quit
			}

		case "ctrl+c", "q":
			m.message = "Exiting...\n"
			m.quitting = true
			return m, tea.Quit
		}

	case tea.WindowSizeMsg:

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

	var question string
	var extra string

	switch m.currentStep {
	case stepSystemUpdate:
		question = questionStyle.Render("Would you like to update the system? (y/n)\n")
	case stepDotfilesUpdate:
		question = questionStyle.Render("Dotfiles updates available. Apply? (y/n)\n")
		extra = infoStyle.Render(m.dotfilesChanges)
	}

	loading := m.spinner.View()

	if extra != "" {
		return fmt.Sprintf("%s\n\n%s\n%s\n\n%s", header, question, extra, loading)
	}
	return fmt.Sprintf("%s\n\n%s\n\n%s", header, question, loading)
}

func main() {
	m := initialModel()
	p := tea.NewProgram(m)

	finalModel, err := p.Run()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	fm := finalModel.(model)

	if fm.runUpdate {
		runSystemUpdate()
	}

	if fm.runDotfiles {
		runDotfilesUpdate()
	}

	if !fm.runUpdate && !fm.runDotfiles {
		fmt.Println("No updates were performed.")
	}

	fmt.Println("\nPress Enter to exit...")
	fmt.Scanln()
	os.Exit(0)
}

func runSystemUpdate() {
	fmt.Println("Starting the system update...")

	cmd := exec.Command("yay", "-Syu")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Printf("Error updating system: %v\n", err)
	} else {
		fmt.Println("\nSystem update completed successfully!")
	}
}

func runDotfilesUpdate() {
	fmt.Println("\nUpdating dotfiles...")

	dotfiles := os.Getenv("HOME") + "/dotfiles"
	cmd := exec.Command(dotfiles+"/update.sh")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Printf("Error updating dotfiles: %v\n", err)
	} else {
		fmt.Println("\nDotfiles update completed successfully!")
	}
}
