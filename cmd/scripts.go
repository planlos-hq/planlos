package cmd

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

// Each entry maps to ./<name>.sh in the checkout.
var scripts = []struct{ name, short, use string }{
	{"clone", "Clone all planlos repos", "clone"},
	{"pull", "Pull (fast-forward only) every repo", "pull"},
	{"push", "Push the current branch of every repo", "push"},
	{"commit", "Commit all changes in every repo", "commit <message>"},
	{"clear", "Delete all cloned repos (asks for yes/ja)", "clear"},
	{"start", "Rebuild and start the stack", "start [compose command]"},
	{"stop", "Stop the stack", "stop [compose command]"},
	{"testdata", "Insert fictional test data", "testdata [compose command]"},
}

func scriptsRoot() (string, error) {
	if v := os.Getenv("PLANLOS_ROOT"); v != "" {
		return v, nil
	}
	return os.Getwd()
}

func init() {
	for _, s := range scripts {
		name := s.name
		rootCmd.AddCommand(&cobra.Command{
			Use:                s.use,
			Short:              s.short,
			DisableFlagParsing: true, // pass everything through to the script
			RunE: func(cmd *cobra.Command, args []string) error {
				if len(args) == 1 && (args[0] == "-h" || args[0] == "--help") {
					return cmd.Help()
				}
				r, err := scriptsRoot()
				if err != nil {
					return err
				}
				c := exec.Command("bash", append([]string{filepath.Join(r, name+".sh")}, args...)...)
				c.Stdin, c.Stdout, c.Stderr = os.Stdin, os.Stdout, os.Stderr
				err = c.Run()

				// scripts print their own errors
				var ee *exec.ExitError
				if errors.As(err, &ee) {
					os.Exit(ee.ExitCode())
				}
				return err
			},
		})
	}
}
